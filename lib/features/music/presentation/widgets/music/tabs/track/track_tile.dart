import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mechanix_music/core/utils/app_logger.dart';
import 'package:mechanix_music/core/utils/app_routes.dart';
import 'package:mechanix_music/core/utils/colors.dart';
import 'package:mechanix_music/core/utils/icons.dart';
import 'package:mechanix_music/features/music/bloc/player/player_bloc.dart';
import 'package:mechanix_music/features/music/bloc/player/player_event.dart';
import 'package:mechanix_music/features/music/data/models/song_model.dart';

class TrackTile extends StatelessWidget {
  final SongModel song;

  const TrackTile({super.key, required this.song});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      minVerticalPadding: 20,
      dense: false,
      onTap: () => {
        AppLogger.i('Song tapped: ${song.title} by ${song.artist}'),
        context.read<PlaybackBloc>().add(PlaybackPlay(song)),
        Navigator.pushNamed(context, AppRoutes.player),
      },
      leading: _ArtworkWidget(artworkPath: song.artworkPath),
      title: Text(
        song.title,
        style: const TextStyle(fontSize: 20, color: MusicColors.titleColor),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        song.artist,
        style: const TextStyle(fontSize: 16, color: MusicColors.timeLabelColor),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: SizedBox(
        width: 40,
        height: 40,
        child: Image.asset(MusicIcons.threedotIcon, width: 28, height: 28),
      ),
    );
  }
}

class _ArtworkWidget extends StatelessWidget {
  final String? artworkPath;

  const _ArtworkWidget({this.artworkPath});

  @override
  Widget build(BuildContext context) {
    if (artworkPath != null) {
      final file = File(artworkPath!);
      if (file.existsSync()) {
        return CircleAvatar(radius: 26, backgroundImage: FileImage(file));
      }
    }

    return _fallback();
  }

  Widget _fallback() {
    return const CircleAvatar(
      radius: 26,
      backgroundImage: AssetImage(MusicIcons.artworkIcon),
    );
  }
}
