import 'package:mechanix_music/features/music/data/models/song_model.dart';

abstract class SongRepository {
  Future<List<SongModel>> syncInitialSongLibrary();
}
