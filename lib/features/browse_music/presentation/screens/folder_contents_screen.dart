import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mechanix_music/core/utils/app_logger.dart';
import 'package:mechanix_music/core/utils/app_routes.dart';
import 'package:mechanix_music/features/browse_music/bloc/browse_folder_bloc.dart';
import 'package:mechanix_music/features/browse_music/bloc/browse_folder_event.dart';
import 'package:mechanix_music/features/browse_music/bloc/browse_folder_state.dart';
import 'package:mechanix_music/features/browse_music/data/models/file_system_entry.dart';
import 'package:mechanix_music/features/browse_music/data/repository/browse_repository_impl.dart';
import 'package:mechanix_music/features/browse_music/presentation/widgets/folder_contents_screen/folder_content_body.dart';
import 'package:mechanix_music/features/music/bloc/player/player_bloc.dart';
import 'package:mechanix_music/features/music/bloc/player/player_event.dart';
import 'package:mechanix_music/features/music/data/models/song_model.dart';

import '../widgets/folder_contents_screen/breadcrumbs_header.dart';
import '../widgets/folder_contents_screen/selection_bottom_bar.dart';
import '../widgets/folder_contents_screen/selection_header.dart';

class FolderContentsScreen extends StatefulWidget {
  final String initialPath;
  final String folderName;

  const FolderContentsScreen({
    super.key,
    required this.initialPath,
    required this.folderName,
  });

  @override
  State<FolderContentsScreen> createState() => _FolderContentsScreenState();
}

class _FolderContentsScreenState extends State<FolderContentsScreen> {
  late final BrowseFolderBloc _bloc;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _bloc = BrowseFolderBloc(
      repository: BrowseRepositoryImpl(),
      directoryPath: widget.initialPath,
      folderName: widget.folderName,
    )..add(const BrowseFolderLoad());
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _bloc.close();
    super.dispose();
  }

  void _onScroll() {
    final position = _scrollController.position;
    final isNearBottom = position.pixels >= position.maxScrollExtent - 200;

    if (!isNearBottom) return;

    if (_bloc.state.hasMore && !_bloc.state.isLoadingMore) {
      _bloc.add(const BrowseFolderLoadMore());
    }
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  void _playFile(FileSystemEntry selectedEntry, List<FileSystemEntry> allEntries) {
    final audioEntries = allEntries.where((e) => !e.isDirectory).toList();

    final songModels = audioEntries.map((e) {
      return SongModel(
        id: e.path,
        path: e.path,
        title: e.name,
        artist: 'Local File',
        album: widget.folderName,
      );
    }).toList();

    final selectedSong = songModels.firstWhere(
      (song) => song.path == selectedEntry.path,
      orElse: () => SongModel(
        id: selectedEntry.path,
        path: selectedEntry.path,
        title: selectedEntry.name,
        artist: 'Local File',
        album: widget.folderName,
      ),
    );

    AppLogger.i('Folder Playback: playing ${selectedSong.title} from folder');

    final playbackBloc = context.read<PlaybackBloc>();
    playbackBloc.add(PlaybackListUpdated(songModels));
    playbackBloc.add(PlaybackPlay(selectedSong));

    Navigator.pushNamed(context, AppRoutes.player);
  }

  void _enterSelectionMode(String path) {
    _bloc.add(BrowseFolderSetSelectionMode(path: path));
  }

  void _exitSelectionMode() {
    _bloc.add(const BrowseFolderSetSelectionMode());
  }

  void _toggleSelection(String path) {
    _bloc.add(BrowseFolderToggleSelection(path));
  }

  void _selectAll() {
    _bloc.add(const BrowseFolderSelectAll());
  }

  Future<void> _saveToObjectBox(Set<String> selectedPaths) async {
    if (selectedPaths.isEmpty) return;

    final pathsToSave = selectedPaths.toList();

    AppLogger.i('Saving ${pathsToSave.length} songs to ObjectBox');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Saving ${pathsToSave.length} song(s) to library...'),
        backgroundColor: const Color(0xFF151515),
        duration: const Duration(milliseconds: 500),
      ),
    );

    // await songRepository.addSongsByPaths(pathsToSave);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully saved ${pathsToSave.length} song(s) to library'),
          backgroundColor: Colors.green.shade900,
          duration: const Duration(seconds: 2),
        ),
      );
      _exitSelectionMode();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BrowseFolderBloc, BrowseFolderState>(
      bloc: _bloc,
      builder: (context, state) {
        return Scaffold(
          backgroundColor: Colors.black,
          body: SafeArea(
            child: Column(
              children: [
                if (state.isSelectionMode)
                  SelectionHeader(
                    selectedCount: state.selectedPaths.length,
                  )
                else
                  BreadcrumbsHeader(
                    currentPath: state.directoryPath,
                    initialPath: widget.initialPath,
                    rootTitle: widget.folderName,
                    onNavigate: (newPath) {
                      _bloc.add(BrowseFolderNavigate(newPath));
                    },
                    onPop: () => Navigator.pop(context),
                  ),
                Expanded(
                  child: FolderContentsBody(
                    state: state,
                    scrollController: _scrollController,
                    formatDate: _formatDate,
                    onDirectoryTap: (path) {
                      if (state.isSelectionMode) {
                        _exitSelectionMode();
                      }
                      _bloc.add(BrowseFolderNavigate(path));
                    },
                    onFileTap: _playFile,
                    onFileLongPress: _enterSelectionMode,
                    onToggleSelection: _toggleSelection,
                    onRetry: () => _bloc.add(const BrowseFolderLoad()),
                  ),
                ),
                if (state.isSelectionMode)
                  SelectionBottomBar(
                    onCancel: _exitSelectionMode,
                    onSelectAll: _selectAll,
                    onSave: () => _saveToObjectBox(state.selectedPaths),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}