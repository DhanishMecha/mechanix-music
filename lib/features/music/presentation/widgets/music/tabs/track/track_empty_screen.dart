import 'package:flutter/material.dart';
import 'package:mechanix_music/core/utils/colors.dart';
import 'package:mechanix_music/core/utils/icons.dart';

class TrackEmptyScreen extends StatelessWidget {
  const TrackEmptyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 10,
        children: [
          Image.asset(MusicIcons.discIcon, width: screenWidth * 0.52),

          const Text(
            "No music tracks available",
            style: TextStyle(color: MusicColors.placeholderColor, fontSize: 18),
          ),
        ],
      ),
    );
  }
}
