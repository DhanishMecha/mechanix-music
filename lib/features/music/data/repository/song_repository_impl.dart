import 'dart:io';
import 'package:hive/hive.dart';
import 'package:mechanix_music/core/exceptions/app_exceptions.dart';
import 'package:mechanix_music/core/services/file_scanner_service.dart';
import 'package:mechanix_music/core/utils/app_logger.dart';
import 'package:mechanix_music/core/utils/constants.dart';
import 'package:mechanix_music/features/music/data/models/song_model.dart';
import 'package:mechanix_music/features/music/data/repository/song_repository.dart';

class SongRepositoryImpl extends SongRepository {
  final FileScannerService _fileScannerService = FileScannerService();
  Box<SongModel> get _box => Hive.box<SongModel>(Constants.musicTable);

  Future<void> ensureHiveConnected() async {
    try {
      if (!Hive.isBoxOpen(Constants.musicTable)) {
        await initializeHive();
        await Hive.openBox<SongModel>(Constants.musicTable);
      }
    } catch (e) {
      AppLogger.e('Failed to open Hive box: $e');
      if (e is FileSystemException && e.message.contains('lock failed')) {
        throw AppAlreadyRunningException();
      }
      rethrow;
    }
  }

  Future<void> initializeHive() async {
    try {
      final home = Platform.environment['HOME'];
      final baseDir = '$home/.config';
      final appDir = Directory('$baseDir/mechanix_music');
      final exists = await appDir.exists();

      if (!exists) {
        await appDir.create(recursive: true);
      }

      Hive.init(appDir.path);
    } catch (e) {
      AppLogger.e('Failed to initialize Hive: $e');
    }
  }

  @override
  Future<List<SongModel>> syncInitialSongLibrary() async {
    try {
      await ensureHiveConnected();

      final diskMap = await _fileScannerService.scanDirectory(
        Constants.musicDir,
      );

      await _box.clear();
      await _box.putAll(diskMap);

      AppLogger.i(
        '[SongRepository] Synced ${diskMap.length} songs from '
        '${Constants.musicDir}',
      );

      return _box.values.toList();
    } on AppAlreadyRunningException catch (_) {
      rethrow;
    } catch (e) {
      AppLogger.e('[SongRepository] scanAndSyncDefaultDir failed: $e');
      return [];
    }
  }
}
