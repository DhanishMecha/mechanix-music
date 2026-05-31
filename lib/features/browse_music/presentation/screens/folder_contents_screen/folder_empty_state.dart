import 'package:flutter/material.dart';

class FolderEmptyState extends StatelessWidget {
  const FolderEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_open_outlined,
            size: 64,
            color: Color(0xFF808080),
          ),
          SizedBox(height: 16),
          Text(
            'No audio files or folders found',
            style: TextStyle(
              color: Color(0xFF808080),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}