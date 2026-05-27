import 'package:flutter/material.dart';
import 'package:mechanix_music/core/utils/colors.dart';

class MusicButton extends StatelessWidget {
  const MusicButton({
    super.key,
    required this.iconPath,
    required this.isSelected,
    required this.onTap,
    this.boxSize = 44,
    this.iconSize = 28,
  });

  final String iconPath;
  final bool isSelected;
  final VoidCallback onTap;
  final double boxSize;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      iconSize: iconSize,
      padding: EdgeInsets.zero,
      constraints: BoxConstraints.tightFor(width: boxSize, height: boxSize),
      // for tap effect
      // style: ButtonStyle(
      //   backgroundColor: WidgetStateProperty.all(
      //     isSelected ? MusicColors.borderColor : Colors.transparent,
      //   ),
      //   shape: WidgetStateProperty.all(
      //     RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      //   ),
      //   // Subtle white flash on press for tap feedback.
      //   overlayColor: WidgetStateProperty.resolveWith((states) {
      //     if (states.contains(WidgetState.pressed)) {
      //       return const Color(0x22FFFFFF);
      //     }
      //     return Colors.transparent;
      //   }),
      // ),
      icon: Image.asset(
        iconPath,
        width: iconSize,
        height: iconSize,
        color: MusicColors.titleColor,
      ),
    );
  }
}
