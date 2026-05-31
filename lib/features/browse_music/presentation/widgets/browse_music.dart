import 'package:flutter/material.dart';
import 'package:mechanix_music/core/utils/browse_folder_options.dart';
import 'package:mechanix_music/features/browse_music/data/models/browse_folder_item.dart';
import 'package:mechanix_music/features/browse_music/data/repository/browse_repository.dart';
import 'package:mechanix_music/features/browse_music/data/repository/browse_repository_impl.dart';
import 'package:mechanix_music/features/browse_music/presentation/screens/folder_contents_screen/folder_contents_screen.dart';
import 'package:mechanix_music/features/browse_music/presentation/widgets/browse_folder_tile.dart';
import 'package:mechanix_music/features/browse_music/presentation/widgets/browse_section_header.dart';

class BrowseMusic extends StatefulWidget {
  const BrowseMusic({super.key});

  @override
  State<BrowseMusic> createState() => _BrowseMusicState();
}

class _BrowseMusicState extends State<BrowseMusic> {
  final BrowseRepository _repository = BrowseRepositoryImpl();

  List<BrowseFolderItem> _drives = const [];

  @override
  void initState() {
    super.initState();
    _loadDrives();
  }

  Future<void> _loadDrives() async {
    final drives = await _repository.getMountedDrives();
    if (mounted) {
      setState(() => _drives = drives);
    }
  }

  void _onFolderTap(BrowseFolderItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FolderContentsScreen(
          initialPath: item.path,
          folderName: item.title,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        // Quick-access folders
        for (final folder in browseFolderOptions)
          BrowseFolderTile(
            icon: folder.icon,
            title: folder.title,
            onTap: () => _onFolderTap(folder),
          ),

        // Hard Drive section
        if (_drives.isNotEmpty) ...[
          const BrowseSectionHeader(title: 'Hard Drive'),
          for (final drive in _drives)
            BrowseFolderTile(
              icon: drive.icon,
              title: drive.title,
              onTap: () => _onFolderTap(drive),
            ),
        ],
      ],
    );
  }
}
