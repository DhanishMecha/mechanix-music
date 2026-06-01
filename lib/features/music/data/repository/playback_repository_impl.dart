
import 'package:audioplayers/audioplayers.dart';
import 'package:mechanix_music/features/music/data/repository/playback_repository.dart';

class PlaybackRepositoryImpl extends PlaybackRepository {
  PlaybackRepositoryImpl({AudioPlayer? audioPlayer})
    : _audioPlayer = audioPlayer ?? AudioPlayer();

  final AudioPlayer _audioPlayer;

  @override
  bool get isPlaying => _audioPlayer.state == PlayerState.playing;

  @override
  Future<void> play(String url) async {
    await _audioPlayer.play(DeviceFileSource(url));
  }

  @override
  Future<void> pause() async {
    await _audioPlayer.pause();
  }

  @override
  Future<void> resume() async {
    await _audioPlayer.resume();
  }

  @override
  Future<void> seek(Duration position) async {
    await _audioPlayer.seek(position);
  }

  @override
  Future<void> stop() async {
    await _audioPlayer.stop();
  }

  @override
  Stream<Duration> get onPositionChanged => _audioPlayer.onPositionChanged;

  @override
  Stream<Duration> get onDurationChanged => _audioPlayer.onDurationChanged;

  @override
  Stream<void> get onSongComplete => _audioPlayer.onPlayerComplete;

  @override
  Future<Duration?> getDuration() => _audioPlayer.getDuration();

  @override
  Future<Duration?> getCurrentPosition() => _audioPlayer.getCurrentPosition();

  @override
  Future<void> dispose() async {
    await _audioPlayer.dispose();
  }
}
