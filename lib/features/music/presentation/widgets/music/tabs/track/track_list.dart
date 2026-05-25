import 'package:flutter/material.dart';
import 'package:mechanix_music/features/music/data/models/song_model.dart';
import 'package:mechanix_music/features/music/presentation/widgets/music/tabs/track/track_tile.dart';

class TrackList extends StatelessWidget {
  final List<SongModel> songs;

  const TrackList({super.key, required this.songs});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      prototypeItem: TrackTile(song: songs.first),
      itemCount: songs.length,
      itemBuilder: (context, index) {
        return TrackTile(song: songs[index]);
      },
    );
  }
}
