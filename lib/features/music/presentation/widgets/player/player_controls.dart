import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mechanix_music/core/utils/icons.dart';
import 'package:mechanix_music/core/widgets/music_button.dart';
import 'package:mechanix_music/features/music/bloc/player/player_bloc.dart';
import 'package:mechanix_music/features/music/bloc/player/player_event.dart';
import 'package:mechanix_music/features/music/bloc/player/player_state.dart';

class PlayerControls extends StatelessWidget {
  const PlayerControls({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        //repeat icon
        MusicButton(
          boxSize: 48,
          iconPath: MusicIcons.repeatIcon,
          isSelected: false,
          onTap: () {},
        ),

        // previous icon
        MusicButton(
          boxSize: 48,
          iconPath: MusicIcons.previousIcon,
          isSelected: false,
          onTap: () {
            context.read<PlaybackBloc>().add(const PlaybackPlayPrevious());
          },
        ),

        // pause/resume icon
        BlocSelector<PlaybackBloc, PlaybackState, bool>(
          selector: (state) => state.status == PlaybackStatus.playing,
          builder: (context, isPlaying) {
            return MusicButton(
              boxSize: 48,
              iconPath: isPlaying
                  ? MusicIcons.pauseIcon
                  : MusicIcons.resumeIcon,
              isSelected: false,
              onTap: () {
                if (isPlaying) {
                  context.read<PlaybackBloc>().add(const PlaybackPause());
                } else {
                  context.read<PlaybackBloc>().add(const PlaybackResume());
                }
              },
            );
          },
        ),

        // next icon
        MusicButton(
          boxSize: 48,
          iconPath: MusicIcons.nextIcon,
          isSelected: false,
          onTap: () {
            context.read<PlaybackBloc>().add(const PlaybackPlayNext());
          },
        ),

        // shuffle icon
        MusicButton(
          boxSize: 48,
          iconPath: MusicIcons.shuffleIcon,
          isSelected: false,
          onTap: () {},
        ),
      ],
    );
  }
}
