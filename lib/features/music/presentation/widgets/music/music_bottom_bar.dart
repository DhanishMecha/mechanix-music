import 'package:flutter/material.dart';
import 'package:mechanix_music/core/utils/colors.dart';
import 'package:mechanix_music/core/utils/icons.dart';

class MusicBottomBar extends StatelessWidget {
  const MusicBottomBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const List<String> _tabIcons = [
    MusicIcons.playcircleIcon,
    MusicIcons.searchIcon,
    MusicIcons.tracksIcon,
    MusicIcons.fileIcon,
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: MusicColors.bottomBarBg,
          boxShadow: [
            BoxShadow(
              color: Color(0x99000000),
              blurRadius: 8,
              offset: Offset(0, 0),
            ),
            BoxShadow(
              color: Color(0x40000000),
              blurRadius: 5,
              offset: Offset(0, -1),
            ),
            BoxShadow(
              color: Color(0x40000000),
              blurRadius: 4,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(
              _tabIcons.length,
              (index) => _TabButton(
                iconPath: _tabIcons[index],
                isSelected: currentIndex == index,
                onTap: () => onTap(index),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.iconPath,
    required this.isSelected,
    required this.onTap,
  });

  final String iconPath;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      iconSize: 28,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(width: 44, height: 44),
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.all(
          isSelected ? MusicColors.borderColor : Colors.transparent,
        ),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
        // Subtle white flash on press for tap feedback.
        overlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) {
            return const Color(0x22FFFFFF);
          }
          return Colors.transparent;
        }),
      ),
      icon: Image.asset(
        iconPath,
        width: 28,
        height: 28,
        color: MusicColors.titleColor,
      ),
    );
  }
}
