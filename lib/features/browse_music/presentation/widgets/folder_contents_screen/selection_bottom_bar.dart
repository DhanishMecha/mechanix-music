import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mechanix_music/core/utils/app_logger.dart';
import 'package:mechanix_music/features/browse_music/bloc/browse_folder_bloc.dart';
import 'package:mechanix_music/features/browse_music/bloc/browse_folder_event.dart';
import 'package:mechanix_music/features/music/bloc/song_bloc.dart';
import 'package:mechanix_music/features/music/bloc/song_event.dart';
import 'package:mechanix_music/l10n/music_localizations.dart';

class SelectionBottomBar extends StatelessWidget {
  const SelectionBottomBar({super.key});

  Future<void> _saveToObjectBox(BuildContext context, Set<String> selectedPaths) async {
    if (selectedPaths.isEmpty) return;

    final pathsToSave = selectedPaths.toList();
    final localizations = AppLocalizations.of(context)!;

    AppLogger.i('Saving ${pathsToSave.length} songs to ObjectBox');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          localizations.savingSongs(pathsToSave.length),
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF151515),
        duration: const Duration(milliseconds: 500),
      ),
    );

    context.read<SongBloc>().add(SongAddByPaths(pathsToSave));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          localizations.queuedSongs(pathsToSave.length),
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.green.shade900,
        duration: const Duration(seconds: 2),
      ),
    );

    context.read<BrowseFolderBloc>().add(const BrowseFolderSetSelectionMode());
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final bloc = context.read<BrowseFolderBloc>();

    return Container(
      height: 64,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
        color: Color(0xFF151515),
        border: Border(top: BorderSide(color: Color(0xFF1C1C1C), width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.close, color: Color(0xFFDDDDDD), size: 28),
            onPressed: () => bloc.add(const BrowseFolderSetSelectionMode()),
            tooltip: localizations!.tooltipCancel,
          ),
          IconButton(
            icon: const Icon(
              Icons.check_circle_outline,
              color: Color(0xFFDDDDDD),
              size: 28,
            ),
            onPressed: () => bloc.add(const BrowseFolderSelectAll()),
            tooltip: localizations.tooltipSelectAll,
          ),
          IconButton(
            icon: const Icon(Icons.check, color: Color(0xFFDDDDDD), size: 28),
            onPressed: () => _saveToObjectBox(context, bloc.state.selectedPaths),
            tooltip: localizations.tooltipSave,
          ),
        ],
      ),
    );
  }
}
