import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mechanix_music/core/utils/app_logger.dart';
import 'package:mechanix_music/features/music/bloc/player/player_event.dart';
import 'package:mechanix_music/features/music/bloc/player/player_state.dart';
import 'package:mechanix_music/features/music/bloc/song_bloc.dart';
import 'package:mechanix_music/features/music/bloc/song_event.dart';
import 'package:mechanix_music/features/music/bloc/song_state.dart';
import 'package:mechanix_music/features/music/data/repository/playback_repository.dart';

class PlaybackBloc extends Bloc<PlaybackEvent, PlaybackState> {
  final PlaybackRepository _repo;
  final SongBloc _songBloc;
  late final StreamSubscription<SongState> _songSub;
  static const _loadMoreThreshold = 5;

  PlaybackBloc(this._repo, this._songBloc)
    : super(
        PlaybackState(
          playbackList: _songBloc.state is SongLoaded
              ? (_songBloc.state as SongLoaded).songs
              : [],
        ),
      ) {
    on<PlaybackPlay>(_onPlay);
    on<PlaybackPause>(_onPause);
    on<PlaybackResume>(_onResume);
    on<PlaybackSeek>(_onSeek);
    on<PlaybackStop>(_onStop);
    on<PlaybackPlayNext>(_onPlayNext);
    on<PlaybackPlayPrevious>(_onPlayPrevious);
    on<PlaybackListUpdated>(_onPlaybackListUpdated);

    _listenToSongBloc();
    _listenToSongComplete();
  }

  void _listenToSongBloc() {
    _songSub = _songBloc.stream.listen((songState) {
      AppLogger.i('[PlaybackBloc] Song state updated: $songState');
      if (songState is SongLoaded) {
        add(PlaybackListUpdated(songState.songs));
      }
    });
  }

  void _listenToSongComplete() {
    _repo.onSongComplete.listen((_) {
      AppLogger.i('[PlaybackBloc] Song completed, attempting to play next...');
      if (state.hasNext) {
        add(const PlaybackPlayNext());
      } else {
        AppLogger.i('[PlaybackBloc] No next song available — pausing playback');
        add(const PlaybackPause());
      }
    });
  }

  void _onPlaybackListUpdated(
    PlaybackListUpdated event,
    Emitter<PlaybackState> emit,
  ) {
    final updatedList = event.playbackList;

    // No song playing yet — just sync the list
    if (state.song == null) {
      emit(state.copyWith(playbackList: updatedList));
      return;
    }

    // Find current song in the updated list
    final newIndex = updatedList.indexOf(state.song!);

    if (newIndex == -1) {
      // Current song was deleted — stop playback
      _repo.stop();
      emit(const PlaybackState(status: PlaybackStatus.stopped));
      return;
    }

    // Song still exists — update list and correct the index
    emit(state.copyWith(playbackList: updatedList, currentIndex: newIndex));
  }

  Future<void> _onPlay(PlaybackPlay event, Emitter<PlaybackState> emit) async {
    try {
      final index = state.playbackList.indexOf(event.song);

      emit(
        state.copyWith(
          status: PlaybackStatus.loading,
          song: event.song,
          currentIndex: index,
        ),
      );

      await _repo.play(event.song.path);
      emit(state.copyWith(status: PlaybackStatus.playing));
    } catch (e) {
      emit(state.copyWith(status: PlaybackStatus.failure, error: e.toString()));
    }
  }

  Future<void> _onPlayNext(
    PlaybackPlayNext event,
    Emitter<PlaybackState> emit,
  ) async {
    try {
      if (!state.hasNext) return;

      final nextIndex = state.currentIndex + 1;
      final nextSong = state.playbackList[nextIndex];

      // Remaining songs after this next play
      final remaining = state.playbackList.length - 1 - nextIndex;

      if (remaining <= _loadMoreThreshold) {
        _songBloc.add(const SongLoadMore());
      }

      emit(
        state.copyWith(
          status: PlaybackStatus.loading,
          song: nextSong,
          currentIndex: nextIndex,
        ),
      );

      await _repo.play(nextSong.path);
      emit(state.copyWith(status: PlaybackStatus.playing));
    } catch (e) {
      emit(state.copyWith(status: PlaybackStatus.failure, error: e.toString()));
    }
  }

  Future<void> _onPlayPrevious(
    PlaybackPlayPrevious event,
    Emitter<PlaybackState> emit,
  ) async {
    try {
      if (!state.hasPrevious) return;

      final prevIndex = state.currentIndex - 1;
      final prevSong = state.playbackList[prevIndex];

      emit(
        state.copyWith(
          status: PlaybackStatus.loading,
          song: prevSong,
          currentIndex: prevIndex,
        ),
      );

      await _repo.play(prevSong.path);
      emit(state.copyWith(status: PlaybackStatus.playing));
    } catch (e) {
      emit(state.copyWith(status: PlaybackStatus.failure, error: e.toString()));
    }
  }

  Future<void> _onPause(
    PlaybackPause event,
    Emitter<PlaybackState> emit,
  ) async {
    try {
      await _repo.pause();
      emit(state.copyWith(status: PlaybackStatus.paused));
    } catch (e) {
      emit(state.copyWith(status: PlaybackStatus.failure, error: e.toString()));
    }
  }

  Future<void> _onResume(
    PlaybackResume event,
    Emitter<PlaybackState> emit,
  ) async {
    try {
      await _repo.resume();
      emit(state.copyWith(status: PlaybackStatus.playing));
    } catch (e) {
      emit(state.copyWith(status: PlaybackStatus.failure, error: e.toString()));
    }
  }

  Future<void> _onSeek(PlaybackSeek event, Emitter<PlaybackState> emit) async {
    try {
      await _repo.seek(event.position);
    } catch (e) {
      emit(state.copyWith(status: PlaybackStatus.failure, error: e.toString()));
    }
  }

  Future<void> _onStop(PlaybackStop event, Emitter<PlaybackState> emit) async {
    try {
      await _repo.stop();
      emit(const PlaybackState(status: PlaybackStatus.stopped));
    } catch (e) {
      emit(state.copyWith(status: PlaybackStatus.failure, error: e.toString()));
    }
  }

  @override
  Future<void> close() async {
    await _songSub.cancel();
    await _repo.dispose();
    return super.close();
  }
}
