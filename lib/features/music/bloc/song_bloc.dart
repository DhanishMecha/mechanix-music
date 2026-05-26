import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mechanix_music/core/utils/app_logger.dart';
import 'package:mechanix_music/features/music/bloc/song_event.dart';
import 'package:mechanix_music/features/music/bloc/song_state.dart';
import 'package:mechanix_music/features/music/data/models/song_model.dart';
import 'package:mechanix_music/features/music/data/repository/song_repository.dart';

class SongBloc extends Bloc<SongEvent, SongState> {
  final SongRepository songRepository;

  static const int _pageSize = 20;
  int _currentOffset = 0;

  SongBloc({required this.songRepository}) : super(const SongInitial()) {
    on<SongInitialized>(_onSongInitialized);
    on<SongLoadMore>(_onSongLoadMore);
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

    // Snapshot existing songs before fetch
    final previousSongs = current.songs;

    emit(SongLoaded(songs: previousSongs, hasMore: true, isLoadingMore: true));

    try {
      await _fetchPage(emit, previousSongs: previousSongs);
    } catch (e) {
      AppLogger.e('[SongBloc] SongLoadMore failed: $e');
      emit(SongError(e.toString()));
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
