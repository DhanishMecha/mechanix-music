import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mechanix_music/core/utils/app_logger.dart';
import 'package:mechanix_music/core/utils/app_routes.dart';
import 'package:mechanix_music/core/utils/colors.dart';
import 'package:mechanix_music/core/utils/icons.dart';
import 'package:mechanix_music/features/music/bloc/player/player_bloc.dart';
import 'package:mechanix_music/features/music/bloc/player/player_event.dart';
import 'package:mechanix_music/features/music/bloc/player/player_state.dart';
import 'package:mechanix_music/features/music/data/models/song_model.dart';
import 'package:mechanix_music/features/music/presentation/widgets/music/tabs/track/track_equalizer_animation.dart';

class TrackTile extends StatelessWidget {
  final SongModel song;

  const TrackTile({super.key, required this.song});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      minVerticalPadding: 20,
      dense: false,
      onTap: () {
        AppLogger.i('Song tapped: ${song.title} by ${song.artist}');
        final currentSong = context.read<PlaybackBloc>().state.song;
        context.read<PlaybackBloc>().add(PlaybackPlay(song));
        if (currentSong == null) {
          Navigator.pushNamed(context, AppRoutes.player);
        }
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
      trailing: BlocBuilder<PlaybackBloc, PlaybackState>(
        buildWhen: (previous, current) {
          final isCurrentSong = current.song?.id == song.id;
          final wasPreviousSong = previous.song?.id == song.id;

          // Rebuild if this song became active or inactive
          if (isCurrentSong != wasPreviousSong) return true;

          // Rebuild only if this song is playing and status changed
          if (isCurrentSong && previous.status != current.status) return true;

          return false;
        },
        builder: (context, state) {
          final isCurrentSong = state.song?.id == song.id;

          if (!isCurrentSong) return const SizedBox();

          return EqualizerIcon(
            isPlaying: state.status == PlaybackStatus.playing,
          );
        },
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
