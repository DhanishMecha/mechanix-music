import 'package:flutter/material.dart';
import 'package:mechanix_music/features/music/presentation/widgets/music/music_bottom_bar.dart';
import 'package:mechanix_music/features/music/presentation/widgets/music/tabs/more_tab.dart';
import 'package:mechanix_music/features/music/presentation/widgets/music/tabs/play_tab.dart';
import 'package:mechanix_music/features/music/presentation/widgets/music/tabs/search_tab.dart';
import 'package:mechanix_music/features/music/presentation/widgets/music/tabs/track_tab.dart';

class MusicScreen extends StatefulWidget {
  const MusicScreen({super.key});

  @override
  State<MusicScreen> createState() => _MusicScreenState();
}

class _MusicScreenState extends State<MusicScreen> {
  int _currentIndex = 2;

  final List<Widget> _tabs = const [
    Center(child: PlayTab()),
    Center(child: SearchTab()),
    TrackTab(),
    Center(child: MoreTab()),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Music")),
      extendBodyBehindAppBar: false,
      body: IndexedStack(index: _currentIndex, children: _tabs),
      bottomNavigationBar: MusicBottomBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}
