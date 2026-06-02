import 'package:flutter/material.dart';
import 'package:mechanix_music/l10n/music_localizations.dart';

class FolderEmptyState extends StatelessWidget {
  const FolderEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.folder_open_outlined,
            size: 64,
            color: Color(0xFF808080),
          ),
          const SizedBox(height: 16),
          Text(
            localizations!.noFilesFound,
            style: const TextStyle(
              color: Color(0xFF808080),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}