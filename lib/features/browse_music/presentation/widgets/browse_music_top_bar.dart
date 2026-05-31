import 'package:flutter/material.dart';
import 'package:mechanix_music/core/utils/colors.dart';

class BrowseMusicTopBar extends StatelessWidget {
  const BrowseMusicTopBar({super.key});

  @override
  Widget build(BuildContext context) {
    return const Text(
      'Browse music folders',
      style: TextStyle(
        color: MusicColors.appTitleColor,
        fontSize: 16,
        fontWeight: FontWeight.w400,
      ),
    );
  }
}
