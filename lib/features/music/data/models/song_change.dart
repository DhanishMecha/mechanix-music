import 'package:mechanix_music/features/music/data/models/song_model.dart';

enum SongChangeType { upsert, delete }

class SongChange {
  final SongChangeType type;
  final SongModel song;

  const SongChange({required this.type, required this.song});
}