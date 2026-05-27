import 'package:equatable/equatable.dart';
import 'package:mechanix_music/features/music/data/models/song_model.dart';

enum PlaybackStatus { initial, loading, playing, paused, stopped, failure }

class PlaybackState extends Equatable {
  final PlaybackStatus status;
  final SongModel? song;
  final List<SongModel> playbackList;
  final int currentIndex;
  final String? error;

  const PlaybackState({
    this.status = PlaybackStatus.initial,
    this.song,
    this.playbackList = const [],
    this.currentIndex = 0,
    this.error,
  });

  bool get hasNext => currentIndex < playbackList.length - 1;
  bool get hasPrevious => currentIndex > 0;

  PlaybackState copyWith({
    PlaybackStatus? status,
    SongModel? song,
    List<SongModel>? playbackList,
    int? currentIndex,
    String? error,
  }) => PlaybackState(
    status: status ?? this.status,
    song: song ?? this.song,
    playbackList: playbackList ?? this.playbackList,
    currentIndex: currentIndex ?? this.currentIndex,
    error: error ?? this.error,
  );

  @override
  List<Object?> get props => [status, song, playbackList, currentIndex, error];
}
