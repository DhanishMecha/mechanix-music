import 'package:mechanix_music/features/browse_music/data/models/browse_folder_item.dart';
import 'package:mechanix_music/features/browse_music/data/models/file_system_entry.dart';

/// Contract for discovering browsable folder shortcuts and mounted drives.
abstract class BrowseRepository {
  /// Returns mounted hard-drive partitions (excludes snap/loop mounts).
  Future<List<BrowseFolderItem>> getMountedDrives();

  /// Lists directory contents (subdirectories and audio files) with pagination.
  ///
  /// Order is based on the filesystem listing and is not explicitly sorted.
  /// Supports pagination via [offset] and [limit].
  /// Returns `({List<FileSystemEntry> entries, bool hasMore})`.
  Future<({List<FileSystemEntry> entries, bool hasMore})> listDirectory(
    String directoryPath, {
    int offset = 0,
    int limit = 30,
  });
}
