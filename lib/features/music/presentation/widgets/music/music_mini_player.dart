import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mechanix_music/core/utils/app_routes.dart';
import 'package:mechanix_music/core/utils/colors.dart';
import 'package:mechanix_music/core/utils/icons.dart';
import 'package:mechanix_music/core/widgets/music_button.dart';
import 'package:mechanix_music/features/music/bloc/player/player_bloc.dart';
import 'package:mechanix_music/features/music/bloc/player/player_event.dart';
import 'package:mechanix_music/features/music/bloc/player/player_state.dart';
import 'package:mechanix_music/features/music/data/repository/playback_repository.dart';

Widget _buildArtwork(String? path, double size) {
  if (path != null) {
    final file = File(path);
    if (file.existsSync()) {
      return Image.file(file, width: size, height: size, fit: BoxFit.cover);
    }
  }
  return Image.asset(
    MusicIcons.artworkIcon,
    width: size,
    height: size,
    fit: BoxFit.cover,
  );
}

class MusicMiniPlayer extends StatefulWidget {
  const MusicMiniPlayer({super.key});

  @override
  State<MusicMiniPlayer> createState() => _MusicMiniPlayerState();
}

class _MusicMiniPlayerState extends State<MusicMiniPlayer> {
  double _progress = 0.0;

  StreamSubscription<Duration>? _positionSub;

  int _positionMs = 0;
  int _durationMs = 0;

  void _updateProgress() {
    if (_durationMs <= 0) return;
    final next = (_positionMs / _durationMs).clamp(0.0, 1.0);
    if (next != _progress) setState(() => _progress = next);
  }

  @override
  void initState() {
    super.initState();
    final repo = context.read<PlaybackRepository>();

    // Seed duration from bloc state immediately
    _durationMs = context
        .read<PlaybackBloc>()
        .state
        .songDuration
        .inMilliseconds;

    repo.getCurrentPosition().then((pos) {
      if (!mounted || pos == null) return;
      _positionMs = pos.inMilliseconds;
      _updateProgress();
    });

    _positionSub = repo.onPositionChanged.listen((pos) {
      _positionMs = pos.inMilliseconds;
      _updateProgress();
    });
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PlaybackBloc, PlaybackState>(
      listenWhen: (previous, current) =>
          previous.songDuration != current.songDuration,
      listener: (context, state) {
        _durationMs = state.songDuration.inMilliseconds;
        _updateProgress();
      },
      child: GestureDetector(
        onTap: () => Navigator.of(context).pushNamed(AppRoutes.player),
        behavior: HitTestBehavior.translucent,
        child: Container(
          height: 72,
          color: MusicColors.backgroundColor,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              BlocSelector<PlaybackBloc, PlaybackState, String?>(
                selector: (state) => state.song?.artworkPath,
                builder: (context, artworkPath) => _ProgressArtwork(
                  artworkPath: artworkPath,
                  progress: _progress,
                ),
              ),
              const SizedBox(width: 12),

              // Song title / artist
              Expanded(
                child:
                    BlocSelector<PlaybackBloc, PlaybackState, (String, String)>(
                      selector: (state) => (
                        state.song?.title ?? 'Now Playing',
                        state.song?.artist ?? 'Unknown',
                      ),
                      builder: (context, songInfo) {
                        final (title, artist) = songInfo;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          spacing: 4,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                height: 1.2,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              artist,
                              style: const TextStyle(
                                color: MusicColors.timeLabelColor,
                                fontSize: 12,
                                height: 1.25,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        );
                      },
                    ),
              ),

              // Audiocast
              // MusicButton(
              //   iconPath: MusicIcons.audiocastIcon,
              //   boxSize: 44,
              //   iconSize: 24,
              //   isSelected: false,
              //   onTap: () {},
              // ),

              // Play/Pause
              BlocSelector<PlaybackBloc, PlaybackState, bool>(
                selector: (state) =>
                    state.status == PlaybackStatus.playing ||
                    state.status == PlaybackStatus.loading,
                builder: (context, isPlaying) => MusicButton(
                  boxSize: 44,
                  iconSize: 24,
                  iconPath: isPlaying
                      ? MusicIcons.pauseIcon
                      : MusicIcons.resumeIcon,
                  isSelected: false,
                  onTap: () => context.read<PlaybackBloc>().add(
                    isPlaying ? const PlaybackPause() : const PlaybackResume(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgressArtwork extends StatefulWidget {
  const _ProgressArtwork({required this.artworkPath, required this.progress});

  final String? artworkPath;
  final double progress;

  @override
  State<_ProgressArtwork> createState() => _ProgressArtworkState();
}

class _ProgressArtworkState extends State<_ProgressArtwork>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 400),
  );

  late Animation<double> _animation = _buildAnimation(
    from: widget.progress,
    to: widget.progress,
  );

  double _animatedFrom = 0.0;

  Animation<double> _buildAnimation({
    required double from,
    required double to,
  }) => Tween<double>(
    begin: from,
    end: to,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

  @override
  void didUpdateWidget(covariant _ProgressArtwork oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress != widget.progress) {
      _animatedFrom = _animation.value;
      _animation = _buildAnimation(from: _animatedFrom, to: widget.progress);
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final artwork = ClipOval(child: _buildArtwork(widget.artworkPath, 40));

    return SizedBox(
      width: 44,
      height: 44,
      child: AnimatedBuilder(
        animation: _animation,
        child: artwork,
        builder: (context, child) => Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: const Size(44, 44),
              painter: _ProgressBorderPainter(
                progress: _animation.value,
                trackColor: MusicColors.titleColor.withValues(alpha: 0.3),
                progressColor: MusicColors.titleColor,
                borderWidth: 4,
                radius: 20,
              ),
            ),
            child!,
          ],
        ),
      ),
    );
  }
}

class _ProgressBorderPainter extends CustomPainter {
  const _ProgressBorderPainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
    required this.borderWidth,
    required this.radius,
  });

  final double progress;
  final Color trackColor;
  final Color progressColor;
  final double borderWidth;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final rect = Rect.fromCircle(center: center, radius: radius);

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = borderWidth,
    );

    if (progress > 0) {
      canvas.drawArc(
        rect,
        -pi / 2,
        -progress * 2 * pi,
        false,
        Paint()
          ..color = progressColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = borderWidth
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ProgressBorderPainter old) =>
      old.progress != progress ||
      old.trackColor != trackColor ||
      old.progressColor != progressColor ||
      old.borderWidth != borderWidth ||
      old.radius != radius;
}
