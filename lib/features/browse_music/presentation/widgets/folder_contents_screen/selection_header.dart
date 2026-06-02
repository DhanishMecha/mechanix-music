import 'package:flutter/material.dart';
import 'package:mechanix_music/l10n/music_localizations.dart';

class SelectionHeader extends StatelessWidget {
  final int selectedCount;

  const SelectionHeader({
    super.key,
    required this.selectedCount,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final title = selectedCount == 0
        ? localizations!.noSelection
        : localizations!.selectedCount(selectedCount);

    return Container(
      height: 64,
      width: double.infinity,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: Colors.black,
        border: Border(
          bottom: BorderSide(color: Color(0xFF1C1C1C), width: 1),
        ),
      ),
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xFFFFFFFF),
          fontSize: 18,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }
}
