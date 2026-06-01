import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mechanix_music/core/utils/app_logger.dart';
import 'package:mechanix_music/features/music/bloc/song_event.dart';
import 'package:mechanix_music/features/music/bloc/song_state.dart';
import 'package:mechanix_music/features/music/data/models/song_change.dart';
import 'package:mechanix_music/features/music/data/models/song_model.dart';
import 'package:mechanix_music/features/music/data/repository/song_repository.dart';

class SongBloc extends Bloc<SongEvent, SongState> {
  final SongRepository songRepository;

  static const int _pageSize = 20;
  int _currentOffset = 0;
  StreamSubscription<SongChange>? _songChangedSub;

  SongBloc({required this.songRepository}) : super(const SongInitial()) {
    on<SongInitialized>(_onSongInitialized);
    on<SongLoadMore>(_onSongLoadMore);
    on<SongUpsert>(_onSongUpsert);
    on<SongDelete>(_onSongDelete);
    on<SongAddByPaths>(_onSongAddByPaths);

    _songChangedSub = songRepository.onSongChanged.listen((change) {
      switch (change.type) {
        case SongChangeType.upsert:
          add(SongUpsert(change.song));
        case SongChangeType.delete:
          add(SongDelete(change.song));
      }
    });
  }

  @override
  Future<void> close() {
    _songChangedSub?.cancel();
    return super.close();
  }

  Future<void> _onSongInitialized(
    SongInitialized event,
    Emitter<SongState> emit,
  ) async {
    emit(const SongLoading());
    _currentOffset = 0;

    try {
      AppLogger.i('[SongBloc] Syncing library then loading first page');
      await songRepository.syncInitialSongLibrary();
      await _fetchPage(emit);
    } catch (e) {
      AppLogger.e('[SongBloc] SongInitialized failed: $e');
      emit(SongError(e.toString()));
    }
  }

  Future<void> _onSongLoadMore(
    SongLoadMore event,
    Emitter<SongState> emit,
  ) async {
    final current = state;
    if (current is! SongLoaded || !current.hasMore || current.isLoadingMore) {
      return;
    }

    final previousSongs = current.songs;
    emit(SongLoaded(songs: previousSongs, hasMore: true, isLoadingMore: true));

    try {
      await _fetchPage(emit, previousSongs: previousSongs);
    } catch (e) {
      AppLogger.e('[SongBloc] SongLoadMore failed: $e');
      emit(SongError(e.toString()));
    }
  }

  void _onSongUpsert(SongUpsert event, Emitter<SongState> emit) {
    final current = state;
    if (current is! SongLoaded) return;

    final songs = List<SongModel>.from(current.songs);
    final index = songs.indexWhere((s) => s.path == event.song.path);

    if (index != -1) {
      // Existing song updated — replace in place
      songs[index] = event.song;
      AppLogger.i('[SongBloc] Updated in state: ${event.song.path}');
    } else {
      // New song — insert sorted by title
      songs.add(event.song);
      songs.sort((a, b) => a.title.compareTo(b.title));
      _currentOffset++;
      AppLogger.i('[SongBloc] Inserted in state: ${event.song.path}');
    }

    emit(SongLoaded(songs: songs, hasMore: current.hasMore));
  }

  void _onSongDelete(SongDelete event, Emitter<SongState> emit) {
    final current = state;
    if (current is! SongLoaded) return;

    final songs = List<SongModel>.from(current.songs)
      ..removeWhere((s) => s.path == event.song.path);

    _currentOffset = (_currentOffset - 1).clamp(0, _currentOffset);

    AppLogger.i('[SongBloc] Removed from state: ${event.song.path}');
    emit(SongLoaded(songs: songs, hasMore: current.hasMore));
  }

  Future<void> _onSongAddByPaths(
    SongAddByPaths event,
    Emitter<SongState> emit,
  ) async {
    if (event.paths.isEmpty) return;

    AppLogger.i('[SongBloc] Adding ${event.paths.length} song(s) by path');

    try {
      await songRepository.addSongsByPaths(event.paths);
      AppLogger.i('[SongBloc] SongAddByPaths completed');
    } catch (e) {
      AppLogger.e('[SongBloc] SongAddByPaths failed: $e');
    }
  }

  Future<void> _fetchPage(
    Emitter<SongState> emit, {
    List<SongModel> previousSongs = const [],
  }) async {
    final page = await songRepository.getSongs(
      offset: _currentOffset,
      limit: _pageSize,
    );

    _currentOffset += page.length;

    final totalCount = await songRepository.getSongCount();
    final hasMore = _currentOffset < totalCount;

    AppLogger.i(
      '[SongBloc] Loaded ${page.length} songs '
      '(offset: $_currentOffset / $totalCount)',
    );

    emit(SongLoaded(songs: [...previousSongs, ...page], hasMore: hasMore));
  }
}
