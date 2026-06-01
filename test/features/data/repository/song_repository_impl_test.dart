import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mechanix_music/core/services/file_scanner_service.dart';
import 'package:mechanix_music/features/music/data/models/song_change.dart';
import 'package:mechanix_music/features/music/data/models/song_model.dart';
import 'package:mechanix_music/features/music/data/repository/song_repository_impl.dart';
import 'package:mechanix_music/objectbox.g.dart';
import 'package:mocktail/mocktail.dart';

class MockFileScannerService extends Mock implements FileScannerService {}

void main() {
  late Store store;
  late Box<SongModel> box;
  late MockFileScannerService scanner;
  late Directory tempMusicDir;
  late SongRepositoryImpl repository;

  setUpAll(() {
    // Allow mocktail to use SongModel in `any()`/argument matchers if needed.
    registerFallbackValue(
      SongModel(id: 'fallback', path: '/fallback', title: 't', artist: 'a'),
    );
  });

  setUp(() async {
    store = Store(
      getObjectBoxModel(),
      directory: 'memory:test-${DateTime.now().microsecondsSinceEpoch}',
    );
    box = store.box<SongModel>();
    scanner = MockFileScannerService();
    tempMusicDir = await Directory.systemTemp.createTemp('repo_test_music_');

    repository = SongRepositoryImpl(
      fileScannerService: scanner,
      store: store,
      musicDirectoryProvider: () => tempMusicDir.path,
    );
  });

  tearDown(() async {
    repository.closeStore();
    if (!store.isClosed()) store.close();
    if (await tempMusicDir.exists()) {
      await tempMusicDir.delete(recursive: true);
    }
  });

  SongModel makeSong(String id, String path, String title) => SongModel(
    id: id,
    path: path,
    title: title,
    artist: 'artist-$id',
  );

  group('getSongs', () {
    test('returns songs ordered by title', () async {
      box.putMany([
        makeSong('1', '/a.mp3', 'Charlie'),
        makeSong('2', '/b.mp3', 'Alpha'),
        makeSong('3', '/c.mp3', 'Bravo'),
      ]);

      final result = await repository.getSongs(offset: 0, limit: 10);

      expect(
        result.map((s) => s.title),
        ['Alpha', 'Bravo', 'Charlie'],
      );
    });

    test('respects offset and limit', () async {
      box.putMany([
        makeSong('1', '/a.mp3', 'Alpha'),
        makeSong('2', '/b.mp3', 'Bravo'),
        makeSong('3', '/c.mp3', 'Charlie'),
        makeSong('4', '/d.mp3', 'Delta'),
      ]);

      final result = await repository.getSongs(offset: 1, limit: 2);

      expect(result.map((s) => s.title), ['Bravo', 'Charlie']);
    });

    test('returns empty list when no songs', () async {
      final result = await repository.getSongs(offset: 0, limit: 10);
      expect(result, isEmpty);
    });
  });

  group('getSongCount', () {
    test('returns the number of stored songs', () async {
      expect(await repository.getSongCount(), 0);

      box.putMany([
        makeSong('1', '/a.mp3', 'Alpha'),
        makeSong('2', '/b.mp3', 'Bravo'),
      ]);

      expect(await repository.getSongCount(), 2);
    });
  });

  group('addSongsByPaths', () {
    test('does nothing for an empty list', () async {
      await repository.addSongsByPaths([]);

      expect(await repository.getSongCount(), 0);
      verifyNever(() => scanner.buildSongModel(any()));
    });

    test('imports new songs and skips already-stored paths', () async {
      box.put(makeSong('existing', '/existing.mp3', 'Existing'));

      when(() => scanner.buildSongModel('/new.mp3')).thenAnswer(
        (_) async => makeSong('new', '/new.mp3', 'New Song'),
      );

      await repository.addSongsByPaths(['/existing.mp3', '/new.mp3']);

      // Scanner should only be asked to build the new path.
      verify(() => scanner.buildSongModel('/new.mp3')).called(1);
      verifyNever(() => scanner.buildSongModel('/existing.mp3'));

      final stored = box.getAll().map((s) => s.path).toSet();
      expect(stored, {'/existing.mp3', '/new.mp3'});
    });

    test('emits an upsert change when a song is added', () async {
      when(() => scanner.buildSongModel('/new.mp3')).thenAnswer(
        (_) async => makeSong('new', '/new.mp3', 'New Song'),
      );

      final changes = expectLater(
        repository.onSongChanged,
        emits(
          isA<SongChange>()
              .having((c) => c.type, 'type', SongChangeType.upsert)
              .having((c) => c.song.path, 'path', '/new.mp3'),
        ),
      );

      await repository.addSongsByPaths(['/new.mp3']);
      await changes;
    });

    test('skips paths the scanner cannot build a model for', () async {
      when(() => scanner.buildSongModel('/broken.mp3'))
          .thenAnswer((_) async => null);

      await repository.addSongsByPaths(['/broken.mp3']);

      expect(await repository.getSongCount(), 0);
      verify(() => scanner.buildSongModel('/broken.mp3')).called(1);
    });
  });

  group('syncInitialSongLibrary', () {
    test('replaces the library with the scanned songs and returns true',
        () async {
      box.put(makeSong('stale', '/old.mp3', 'Stale'));

      when(() => scanner.scanDirectory(tempMusicDir.path)).thenAnswer(
        (_) async => {
          'a': makeSong('a', '/songs/a.mp3', 'A'),
          'b': makeSong('b', '/songs/b.mp3', 'B'),
        },
      );

      final result = await repository.syncInitialSongLibrary();

      expect(result, isTrue);
      final paths = box.getAll().map((s) => s.path).toSet();
      expect(paths, {'/songs/a.mp3', '/songs/b.mp3'});
    });

    test('returns false when scanning throws', () async {
      box.put(makeSong('stale', '/old.mp3', 'Stale'));

      when(() => scanner.scanDirectory(tempMusicDir.path))
          .thenThrow(Exception('scan failed'));

      final result = await repository.syncInitialSongLibrary();

      expect(result, isFalse);
      // Existing data should be untouched because the transaction never ran.
      expect(box.getAll().single.path, '/old.mp3');
    });
  });
}
