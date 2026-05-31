import 'dart:io';

import 'package:flutter/material.dart';
import 'package:mechanix_music/features/browse_music/data/models/browse_folder_item.dart';

final List<BrowseFolderItem> browseFolderOptions = [
  BrowseFolderItem(
    icon: Icons.home_outlined,
    title: 'Home directory',
    path: Platform.environment['HOME'] ?? '/home',
  ),
  BrowseFolderItem(
    icon: Icons.access_time,
    title: 'Recents',
    path: '${Platform.environment['HOME'] ?? '/home'}/Recent',
  ),
  BrowseFolderItem(
    icon: Icons.download_outlined,
    title: 'Downloads',
    path: '${Platform.environment['HOME'] ?? '/home'}/Downloads',
  ),
  BrowseFolderItem(
    icon: Icons.description_outlined,
    title: 'Documents',
    path: '${Platform.environment['HOME'] ?? '/home'}/Documents',
  ),
];
