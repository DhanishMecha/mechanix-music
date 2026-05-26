import 'dart:io';
import 'package:mechanix_music/core/exceptions/app_exceptions.dart';
import 'package:mechanix_music/core/services/file_scanner_service.dart';
import 'package:mechanix_music/core/utils/app_logger.dart';
import 'package:mechanix_music/core/utils/constants.dart';
import 'package:mechanix_music/features/music/data/models/song_model.dart';
import 'package:mechanix_music/features/music/data/repository/song_repository.dart';
import 'package:mechanix_music/objectbox.g.dart';

class SongRepositoryImpl extends SongRepository {
  final FileScannerService _fileScannerService = FileScannerService();

  Store? _store;
  Box<SongModel>? _box;

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
      final appDir = Directory('$home/.config/mechanix_music/objectbox');
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
    _store?.close();
    _store = null;
    _box = null;
  }

  @override
  Future<bool> syncInitialSongLibrary() async {
    try {
      await ensureStoreConnected();

      final diskMap = await _fileScannerService.scanDirectory(
        Constants.musicDir,
      );

      final incomingSongs = diskMap.values.toList();

      _store!.runInTransaction(TxMode.write, () {
        // Clear existing records
        _box!.removeAll();

        _box!.putMany(incomingSongs);
      });

      AppLogger.i(
        '[SongRepository] Synced ${incomingSongs.length} songs from '
        '${Constants.musicDir}',
      );

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
}
