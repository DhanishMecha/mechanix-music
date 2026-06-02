import 'package:flutter/material.dart';
import 'package:mechanix_music/l10n/music_localizations.dart';

class SelectionBottomBar extends StatelessWidget {
  final VoidCallback onCancel;
  final VoidCallback onSelectAll;
  final VoidCallback onSave;

  const SelectionBottomBar({
    super.key,
    required this.onCancel,
    required this.onSelectAll,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
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
            onPressed: onCancel,
            tooltip: localizations!.tooltipCancel,
          ),
          IconButton(
            icon: const Icon(
              Icons.check_circle_outline,
              color: Color(0xFFDDDDDD),
              size: 28,
            ),
            onPressed: onSelectAll,
            tooltip: localizations.tooltipSelectAll,
          ),
          IconButton(
            icon: const Icon(Icons.check, color: Color(0xFFDDDDDD), size: 28),
            onPressed: onSave,
            tooltip: localizations.tooltipSave,
          ),
        ],
      ),
    );
  }
}
