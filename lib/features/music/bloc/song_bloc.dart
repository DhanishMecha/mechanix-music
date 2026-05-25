import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mechanix_music/core/utils/app_logger.dart';
import 'package:mechanix_music/features/music/bloc/song_event.dart';
import 'package:mechanix_music/features/music/bloc/song_state.dart';
import 'package:mechanix_music/features/music/data/repository/song_repository.dart';

class SongBloc extends Bloc<SongEvent, SongState> {
  final SongRepository songRepository;

  SongBloc({required this.songRepository}) : super(SongInitial()) {
    on<SongInitialized>(_onSongInitialized);
  }

  Future<void> _onSongInitialized(
    SongInitialized event,
    Emitter<SongState> emit,
  ) async {
    emit(SongLoading());
    try {
      AppLogger.i('[SongBloc] SongInitialization started');
      final songs = await songRepository.syncInitialSongLibrary();
      emit(SongLoaded(songs));
      AppLogger.i('[SongBloc] SongInitialization completed');
    } catch (e) {
      AppLogger.e('[SongBloc] SongInitialized failed: $e');
      emit(SongError(e.toString()));
    }
  }
}
