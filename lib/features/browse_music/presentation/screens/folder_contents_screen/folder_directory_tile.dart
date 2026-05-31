import 'package:flutter/material.dart';
import 'package:mechanix_music/features/browse_music/data/models/file_system_entry.dart';

class FolderDirectoryTile extends StatelessWidget {
  final FileSystemEntry entry;
  final bool isSelectionMode;
  final String Function(DateTime) formatDate;
  final VoidCallback onTap;

  const FolderDirectoryTile({
    super.key,
    required this.entry,
    required this.isSelectionMode,
    required this.formatDate,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      splashColor: const Color(0x1AFFFFFF),
      highlightColor: const Color(0x0DFFFFFF),
      child: SizedBox(
        height: 72,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              if (isSelectionMode)
                Container(
                  width: 24,
                  height: 24,
                  margin: const EdgeInsets.only(right: 16),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0x33808080),
                      width: 2,
                    ),
                    color: Colors.transparent,
                  ),
                ),
              const Icon(
                Icons.folder_open_outlined,
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
              const Icon(
                Icons.chevron_right,
                size: 24,
                color: Color(0xFF808080),
              ),
            ],
          ),
        ),
      ),
    );
  }
}