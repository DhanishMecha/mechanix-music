import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mechanix_music/core/utils/theme.dart';
import 'package:show_fps/show_fps.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const NotesApp());
}

class NotesApp extends StatelessWidget {
  const NotesApp({super.key});

  @override
  Widget build(BuildContext context) {
    final showFps = Platform.environment['SHOW_FPS'] == 'true';

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      builder: showFps
          ? (context, child) {
              return ShowFPS(visible: showFps, showChart: false, child: child!);
            }
          : null,
      themeMode: ThemeMode.dark,
      darkTheme: AppTheme.dark,
      theme: AppTheme.light,

      home: const Scaffold(body: Text("Music App")),
    );
  }
}
