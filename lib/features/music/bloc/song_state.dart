import 'package:mechanix_music/features/music/data/models/song_model.dart';

sealed class SongState {}

final class SongInitial extends SongState {}

final class SongLoading extends SongState {}

final class SongLoaded extends SongState {
  final List<SongModel> songs;
  SongLoaded(this.songs);
}

final class SongError extends SongState {
  final String message;
  SongError(this.message);
}
