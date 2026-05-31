import 'package:flutter/material.dart';
import 'package:mechanix_music/features/browse_music/data/models/file_system_entry.dart';

class FolderAudioTile extends StatelessWidget {
  final FileSystemEntry entry;
  final bool isSelected;
  final bool isSelectionMode;
  final String Function(DateTime) formatDate;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onToggleSelection;

  const FolderAudioTile({
    super.key,
    required this.entry,
    required this.isSelected,
    required this.isSelectionMode,
    required this.formatDate,
    required this.onTap,
    required this.onLongPress,
    required this.onToggleSelection,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      splashColor: const Color(0x1AFFFFFF),
      highlightColor: const Color(0x0DFFFFFF),
      child: SizedBox(
        height: 72,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              if (isSelectionMode)
                GestureDetector(
                  onTap: onToggleSelection,
                  child: Container(
                    width: 24,
                    height: 24,
                    margin: const EdgeInsets.only(right: 16),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFFADADAD)
                            : const Color(0xFF555555),
                        width: 2,
                      ),
                      color: isSelected
                          ? const Color(0xFFADADAD)
                          : Colors.transparent,
                    ),
                    child: isSelected
                        ? const Icon(
                            Icons.check,
                            size: 16,
                            color: Colors.black,
                          )
                        : null,
                  ),
                ),
              const Icon(
                Icons.music_note_outlined,
                size: 24,
                color: Color(0xFFADADAD),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.name,
                      style: const TextStyle(
                        color: Color(0xFFDDDDDD),
                        fontSize: 18,
                        fontWeight: FontWeight.w400,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatDate(entry.modifiedDate),
                      style: const TextStyle(
                        color: Color(0xFF808080),
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}