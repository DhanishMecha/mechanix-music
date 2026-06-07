import 'dart:async';
import 'dart:io';
import 'package:mechanix_music/core/exceptions/app_exceptions.dart';
import 'package:mechanix_music/core/services/file_scanner_service.dart';
import 'package:mechanix_music/core/utils/app_logger.dart';
import 'package:mechanix_music/core/utils/constants.dart';
import 'package:mechanix_music/core/utils/enums.dart';
import 'package:mechanix_music/core/utils/helper.dart';
import 'package:mechanix_music/features/music/data/models/song_change.dart';
import 'package:mechanix_music/features/music/data/models/song_model.dart';
import 'package:mechanix_music/features/music/data/repository/song_repository.dart';
import 'package:mechanix_music/objectbox.g.dart';

class SongRepositoryImpl extends SongRepository {
  SongRepositoryImpl({
    FileScannerService? fileScannerService,
    Store? store,
    String Function()? musicDirectoryProvider,
  }) : _fileScannerService = fileScannerService ?? FileScannerService(),
       _musicDirectoryProvider = musicDirectoryProvider ?? getMusicDirectory,
       _store = store {
    if (store != null) _box = store.box<SongModel>();
  }

  final FileScannerService _fileScannerService;
  final String Function() _musicDirectoryProvider;

  Store? _store;
  Box<SongModel>? _box;

  StreamSubscription<FileSystemEvent>? _watcherSubscription;
  final Map<String, Timer> _debounceTimers = {};

  // Stream that bloc will listen to for live changes
  final StreamController<SongChange> _onSongChanged =
      StreamController<SongChange>.broadcast();

  @override
  Stream<SongChange> get onSongChanged => _onSongChanged.stream;

  Future<void> ensureStoreConnected() async {
    if (_store != null && _store!.isClosed() == false) return;

    try {
      await _initializeStore();
    } catch (e) {
      AppLogger.e('Failed to open ObjectBox store: $e');
      if (e is FileSystemException && e.message.contains('lock failed')) {
        throw AppAlreadyRunningException();
      }
      rethrow;
    }
  }

  Future<void> _initializeStore() async {
    try {
      final home = Platform.environment['HOME'];
      final appDir = Directory('$home/${Constants.dbPath}');
      final exists = await appDir.exists();

      if (!exists) {
        await appDir.create(recursive: true);
      }

      _store = openStore(directory: appDir.path);
      _box = _store!.box<SongModel>();

      AppLogger.i('[SongRepository] ObjectBox store opened at ${appDir.path}');
    } catch (e) {
      AppLogger.e('Failed to initialize ObjectBox store: $e');
      rethrow;
    }
  }

  void closeStore() {
    _watcherSubscription?.cancel();
    _watcherSubscription = null;

    for (final timer in _debounceTimers.values) {
      timer.cancel();
    }
    _debounceTimers.clear();

    _onSongChanged.close();

    _store?.close();
    _store = null;
    _box = null;
  }

  @override
  Future<bool> syncInitialSongLibrary() async {
    try {
      await ensureStoreConnected();
      final musicDir = _musicDirectoryProvider();

      final diskMap = await _fileScannerService.scanDirectory(musicDir);

      final incomingSongs = diskMap.values.toList();

      _store!.runInTransaction(TxMode.write, () {
        _box!.removeAll();
        _box!.putMany(incomingSongs);
      });

      AppLogger.i(
        '[SongRepository] Synced ${incomingSongs.length} songs from '
        '$musicDir',
      );

      _startWatcher();
      return true;
    } on AppAlreadyRunningException catch (_) {
      rethrow;
    } catch (e) {
      AppLogger.e('[SongRepository] syncInitialSongLibrary failed: $e');
      return false;
    }
  }

  @override
  Future<List<SongModel>> getSongs({
    required int offset,
    required int limit,
  }) async {
    await ensureStoreConnected();

    final query = _box!.query().order(SongModel_.title).build()
      ..offset = offset
      ..limit = limit;

    try {
      return query.find().toList();
    } finally {
      query.close();
    }
  }

  @override
  Future<int> getSongCount() async {
    await ensureStoreConnected();
    return _box!.count();
  }

  @override
  Future<void> addSongsByPaths(List<String> paths) async {
    if (paths.isEmpty) return;
    await ensureStoreConnected();

    // Single bulk query — ObjectBox checks all paths in one index scan.
    final existingPaths = _box!
        .query(SongModel_.path.oneOf(paths))
        .build()
        .find()
        .map((s) => s.path)
        .toSet();

    final newPaths = paths.where((p) => !existingPaths.contains(p)).toList();

    AppLogger.i(
      '[SongRepository] ${existingPaths.length} already in library, '
      '${newPaths.length} to import',
    );

    for (final path in newPaths) {
      try {
        final song = await _fileScannerService.buildSongModel(path);
        if (song == null) {
          AppLogger.i('[SongRepository] Could not build model for: $path');
          continue;
        }

        _box!.put(song);
        AppLogger.i('[SongRepository] Added to library: ${song.title}');
        _onSongChanged.add(SongChange(type: SongChangeType.upsert, song: song));
      } catch (e) {
        AppLogger.e('[SongRepository] addSongsByPaths failed for $path: $e');
      }
    }
  }

  // ── Watcher ──────────────────────────────────────────────────────────────

  void _startWatcher() {
    _watcherSubscription?.cancel();
    final musicDir = _musicDirectoryProvider();
    _watcherSubscription = Directory(musicDir).watch(recursive: false).listen((
      event,
    ) {
      if (!isAudioFile(event.path)) return;

      switch (event.type) {
        case FileSystemEvent.create:
        case FileSystemEvent.modify:
          _debounce(event.path, () => _onUpsert(event.path));

        case FileSystemEvent.delete:
          // Cancel any pending debounce for this path and act immediately
          _debounceTimers[event.path]?.cancel();
          _debounceTimers.remove(event.path);
          _onDelete(event.path);

        case FileSystemEvent.move:
          final moveEvent = event as FileSystemMoveEvent;
          final destination = moveEvent.destination;
          if (destination == null) return;

          // Cancel pending debounce for old path and act immediately
          _debounceTimers[moveEvent.path]?.cancel();
          _debounceTimers.remove(moveEvent.path);
          _onMove(oldPath: moveEvent.path, newPath: destination);
      }
    });

    AppLogger.i('[FileWatcher] Watching $musicDir');
  }

  void _debounce(String path, void Function() action) {
    _debounceTimers[path]?.cancel();
    _debounceTimers[path] = Timer(const Duration(milliseconds: 300), () {
      _debounceTimers.remove(path);
      action();
    });
  }

  Future<void> _onUpsert(String path) async {
    try {
      final song = await _fileScannerService.buildSongModel(path);
      if (song == null) return;

      final existing = _box!
          .query(SongModel_.path.equals(path))
          .build()
          .findFirst();

      if (existing != null) song.obxId = existing.obxId;

      _box!.put(song);
      AppLogger.i('[FileWatcher] Upserted: $path');
      _onSongChanged.add(SongChange(type: SongChangeType.upsert, song: song));
    } catch (e) {
      AppLogger.e('[FileWatcher] Upsert failed for $path: $e');
    }
  }

  void _onDelete(String path) {
    try {
      final existing = _box!
          .query(SongModel_.path.equals(path))
          .build()
          .findFirst();

      if (existing == null) return;

      _box!.remove(existing.obxId);
      AppLogger.i('[FileWatcher] Deleted: $path');
      _onSongChanged.add(
        SongChange(type: SongChangeType.delete, song: existing),
      );
    } catch (e) {
      AppLogger.e('[FileWatcher] Delete failed for $path: $e');
    }
  }

  Future<void> _onMove({
    required String oldPath,
    required String newPath,
  }) async {
    try {
      final existing = _box!
          .query(SongModel_.path.equals(oldPath))
          .build()
          .findFirst();

      if (existing == null) return;

      final updated = await _fileScannerService.buildSongModel(newPath);
      if (updated == null) return;

      updated.obxId = existing.obxId;
      _box!.put(updated);

      AppLogger.i('[FileWatcher] Moved: $oldPath → $newPath');
      _onSongChanged.add(
        SongChange(type: SongChangeType.upsert, song: updated),
      );
    } catch (e) {
      AppLogger.e('[FileWatcher] Move failed $oldPath → $newPath: $e');
    }
  }

  bool isAudioFile(String path) {
    final lower = path.toLowerCase();
    return Constants.audioExt.any((ext) => lower.endsWith(ext));
  }
}
