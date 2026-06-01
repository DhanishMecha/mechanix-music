import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:flutter/material.dart';
import 'package:mechanix_music/core/utils/constants.dart';
import 'package:mechanix_music/features/browse_music/data/models/browse_folder_item.dart';
import 'package:mechanix_music/features/browse_music/data/models/file_system_entry.dart';
import 'package:mechanix_music/features/browse_music/data/repository/browse_repository.dart';
import 'package:path/path.dart' as p;

class BrowseRepositoryImpl implements BrowseRepository {
  BrowseRepositoryImpl({FileSystem? fileSystem})
    : _fs = fileSystem ?? const LocalFileSystem();

  final FileSystem _fs;

  @override
  Future<List<BrowseFolderItem>> getMountedDrives() async {
    final drives = <BrowseFolderItem>[];

    // Always include root
    drives.add(
      const BrowseFolderItem(icon: Icons.storage, title: 'Root (/)', path: '/'),
    );

    // Parse /proc/mounts to find real block-device partitions.
    // This avoids shelling out to external commands which is better
    // for embedded devices with limited process-spawn overhead.
    try {
      final mounts = await _fs.file('/proc/mounts').readAsString();
      for (final line in mounts.split('\n')) {
        if (line.isEmpty) continue;
        final parts = line.split(' ');
        if (parts.length < 2) continue;

        final device = parts[0];
        final mountPoint = parts[1];

        // Only include real block devices mounted under /media or /mnt
        if (!device.startsWith('/dev/')) continue;
        if (!mountPoint.startsWith('/media') &&
            !mountPoint.startsWith('/mnt')) {
          continue;
        }

        // Derive a human-readable label from the mount path
        final label = mountPoint.split('/').last;
        drives.add(
          BrowseFolderItem(icon: Icons.usb, title: label, path: mountPoint),
        );
      }
    } catch (_) {
      // If /proc/mounts is unavailable, return just root
    }

    return drives;
  }

  @override
  Future<({List<FileSystemEntry> entries, bool hasMore})> listDirectory(
    String directoryPath, {
    int offset = 0,
    int limit = 30,
  }) async {
    final dir = _fs.directory(directoryPath);
    if (!await dir.exists()) {
      return (entries: const <FileSystemEntry>[], hasMore: false);
    }

    final entries = <FileSystemEntry>[];
    int skipped = 0;
    int taken = 0;
    bool hasMore = false;

    try {
      await for (final entity in dir.list(
        recursive: false,
        followLinks: false,
      )) {
        final name = p.basename(entity.path);
        if (name.startsWith('.')) continue; // skip hidden entries

        final isDirectory = entity is Directory;
        if (!isDirectory) {
          final extension = p.extension(entity.path).toLowerCase();
          if (!Constants.audioExt.contains(extension)) {
            continue; // only show audio files in the folder browser
          }
        }

        if (skipped < offset) {
          skipped++;
          continue;
        }

        if (taken >= limit) {
          hasMore = true;
          break;
        }

        try {
          final stat = await entity.stat();
          entries.add(
            FileSystemEntry(
              name: name,
              path: entity.path,
              isDirectory: isDirectory,
              modifiedDate: stat.modified,
            ),
          );
          taken++;
        } catch (_) {
          // skip entries we cannot stat
        }
      }
    } catch (_) {
      return (entries: const <FileSystemEntry>[], hasMore: false);
    }

    return (entries: entries, hasMore: hasMore);
  }
}
