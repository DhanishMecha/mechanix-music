import 'package:flutter/material.dart';
import 'package:mechanix_music/features/browse_music/bloc/browse_folder_state.dart';
import 'package:mechanix_music/features/browse_music/data/models/file_system_entry.dart';

import 'folder_audio_tile.dart';
import 'folder_directory_tile.dart';
import 'folder_empty_state.dart';
import 'folder_error_state.dart';
import 'folder_load_more_indicator.dart';

class FolderContentsBody extends StatelessWidget {
  final BrowseFolderState state;
  final ScrollController scrollController;
  final String Function(DateTime) formatDate;
  final void Function(String path) onDirectoryTap;
  final void Function(FileSystemEntry entry, List<FileSystemEntry> allEntries)
  onFileTap;
  final void Function(String path) onFileLongPress;
  final void Function(String path) onToggleSelection;
  final VoidCallback onRetry;

  const FolderContentsBody({
    super.key,
    required this.state,
    required this.scrollController,
    required this.formatDate,
    required this.onDirectoryTap,
    required this.onFileTap,
    required this.onFileLongPress,
    required this.onToggleSelection,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFDDDDDD)),
        ),
      );
    }

    if (state.error != null) {
      return FolderErrorState(error: state.error!, onRetry: onRetry);
    }

    if (state.entries.isEmpty) {
      return const FolderEmptyState();
    }

    return ListView.builder(
      controller: scrollController,
      itemCount: state.entries.length + (state.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == state.entries.length) {
          return const FolderLoadMoreIndicator();
        }

        final entry = state.entries[index];

        if (entry.isDirectory) {
          return FolderDirectoryTile(
            entry: entry,
            formatDate: formatDate,
            onTap: () => onDirectoryTap(entry.path),
          );
        } else {
          final isSelected = state.selectedPaths.contains(entry.path);

          return FolderAudioTile(
            entry: entry,
            isSelected: isSelected,
            isSelectionMode: state.isSelectionMode,
            formatDate: formatDate,
            onTap: () {
              if (state.isSelectionMode) {
                onToggleSelection(entry.path);
              } else {
                onFileTap(entry, state.entries);
              }
            },
            onLongPress: () {
              if (!state.isSelectionMode) {
                onFileLongPress(entry.path);
              } else {
                onToggleSelection(entry.path);
              }
            },
            onToggleSelection: () => onToggleSelection(entry.path),
          );
        }
      },
    );
  }
}
