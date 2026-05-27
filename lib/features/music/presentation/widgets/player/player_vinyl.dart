import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mechanix_music/core/utils/colors.dart';
import 'package:mechanix_music/core/utils/icons.dart';
import 'package:mechanix_music/features/music/bloc/player/player_bloc.dart';
import 'package:mechanix_music/features/music/bloc/player/player_event.dart';
import 'package:mechanix_music/features/music/bloc/player/player_state.dart';
import 'package:mechanix_music/features/music/data/repository/playback_repository.dart';

class PlayerVinyl extends StatefulWidget {
  const PlayerVinyl({super.key});

  @override
  State<PlayerVinyl> createState() => _PlayerVinylState();
}

class _PlayerVinylState extends State<PlayerVinyl>
    with SingleTickerProviderStateMixin {
  late final AnimationController _rotationController;

  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isDragging = false;
  double _dragProgress = 0.0;
  bool _isDragValid = false;

  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration>? _durationSubscription;
  MouseCursor _cursor = MouseCursor.defer;

  @override
  void initState() {
    super.initState();

    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    );

    final repo = context.read<PlaybackRepository>();

    // Get initial values
    repo.getCurrentPosition().then((pos) {
      if (mounted && pos != null && !_isDragging) {
        setState(() {
          _position = pos;
        });
      }
    });

    repo.getDuration().then((dur) {
      if (mounted && dur != null) {
        setState(() {
          _duration = dur;
        });
      }
    });

    _positionSubscription = repo.onPositionChanged.listen((pos) {
      if (mounted && !_isDragging) {
        setState(() {
          _position = pos;
        });
      }
    });

    _durationSubscription = repo.onDurationChanged.listen((dur) {
      if (mounted) {
        setState(() {
          _duration = dur;
        });
      }
    });
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    if (duration == Duration.zero) return '00:00';
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    final secondsStr = seconds.toString().padLeft(2, '0');
    if (hours > 0) {
      final minutesStr = minutes.toString().padLeft(2, '0');
      return '$hours:$minutesStr:$secondsStr';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:$secondsStr';
    }
  }

  void _handleGesture(Offset localPosition, double size, {bool isTap = false}) {
    final outerWidth = size + 110;
    final outerHeight = size + 60;
    final center = Offset(outerWidth / 2, outerHeight / 2);
    final dx = localPosition.dx - center.dx;
    final dy = localPosition.dy - center.dy;

    final dist = sqrt(dx * dx + dy * dy);
    final radius = size / 2 + 18;

    if (isTap || !_isDragging) {
      // Validate that the touch point starts near the curve slider.
      // The curve slider resides in the bottom half (dy >= -10)
      // and has a distance of radius +/- 25 pixels.
      final isNearArc = dy >= -10 && (dist - radius).abs() <= 25;
      if (!isNearArc) {
        _isDragValid = false;
        return;
      }
      _isDragValid = true;
    }

    if (!_isDragValid) return;

    double angle = atan2(dy, dx);
    if (angle < 0) {
      if (dx < 0) {
        angle = pi;
      } else {
        angle = 0.0;
      }
    }

    double progress = (pi - angle) / pi;
    progress = progress.clamp(0.0, 1.0);

    setState(() {
      _isDragging = true;
      _dragProgress = progress;
    });
  }

  void _handleGestureEnd() {
    if (_isDragValid && _isDragging && _duration.inMilliseconds > 0) {
      final seekPosition = Duration(
        milliseconds: (_dragProgress * _duration.inMilliseconds).round(),
      );
      context.read<PlaybackBloc>().add(PlaybackSeek(seekPosition));
      setState(() {
        _isDragging = false;
        _position = seekPosition;
      });
    } else {
      setState(() {
        _isDragging = false;
      });
    }
    _isDragValid = false;
  }

  void _handleHover(Offset localPosition, double size) {
    final outerWidth = size + 110;
    final outerHeight = size + 60;
    final center = Offset(outerWidth / 2, outerHeight / 2);
    final dx = localPosition.dx - center.dx;
    final dy = localPosition.dy - center.dy;

    final dist = sqrt(dx * dx + dy * dy);
    final radius = size / 2 + 18;

    // Bottom half and a distance within radius +/- 20 pixels
    final isNearArc =
        dy >= -10 && dist >= (radius - 20) && dist <= (radius + 20);

    final newCursor = isNearArc ? SystemMouseCursors.click : MouseCursor.defer;
    if (_cursor != newCursor) {
      setState(() {
        _cursor = newCursor;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final size = screenWidth * 0.50;
    final outerWidth = size + 110;
    final outerHeight = size + 60;
    final center = Offset(outerWidth / 2, outerHeight / 2);
    final radius = size / 2 + 18;

    final displayProgress = _isDragging
        ? _dragProgress
        : (_duration.inMilliseconds > 0
              ? (_position.inMilliseconds / _duration.inMilliseconds).clamp(
                  0.0,
                  1.0,
                )
              : 0.0);

    final displayPosition = _isDragging
        ? Duration(
            milliseconds: (_dragProgress * _duration.inMilliseconds).round(),
          )
        : _position;

    return BlocListener<PlaybackBloc, PlaybackState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        if (state.status == PlaybackStatus.playing) {
          _rotationController.repeat();
        } else {
          _rotationController.stop();
        }
      },
      child: BlocBuilder<PlaybackBloc, PlaybackState>(
        builder: (context, state) {
          // Sync rotation controller state
          if (state.status == PlaybackStatus.playing &&
              !_rotationController.isAnimating) {
            _rotationController.repeat();
          } else if (state.status != PlaybackStatus.playing &&
              _rotationController.isAnimating) {
            _rotationController.stop();
          }

          final song = state.song;

          return SizedBox(
            width: outerWidth,
            height: outerHeight,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // 1. Semi-Circular Slider track & thumb (captures gesture inputs)
                Positioned.fill(
                  child: MouseRegion(
                    cursor: _cursor,
                    onHover: (event) => _handleHover(event.localPosition, size),
                    onExit: (_) {
                      setState(() {
                        _cursor = MouseCursor.defer;
                      });
                    },
                    child: GestureDetector(
                      onPanStart: (details) =>
                          _handleGesture(details.localPosition, size),
                      onPanUpdate: (details) =>
                          _handleGesture(details.localPosition, size),
                      onPanEnd: (_) => _handleGestureEnd(),
                      onTapDown: (details) => _handleGesture(
                        details.localPosition,
                        size,
                        isTap: true,
                      ),
                      onTapUp: (_) => _handleGestureEnd(),
                      behavior: HitTestBehavior.opaque,
                      child: CustomPaint(
                        painter: SemiCircularSliderPainter(
                          progress: displayProgress,
                          trackColor: MusicColors.progressBarColor,
                          progressColor: const Color(0xFFDDDDDD),
                          thumbColor: Colors.white,
                          radius: radius,
                        ),
                      ),
                    ),
                  ),
                ),

                // 2. Center Vinyl Artwork
                Center(
                  child: RotationTransition(
                    turns: _rotationController,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Image.asset(
                          MusicIcons.playerDisc,
                          width: size,
                          height: size,
                          fit: BoxFit.cover,
                        ),
                        ClipOval(
                          child: _buildArtworkWidget(
                            song?.artworkPath,
                            size * 0.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 3. Time Labels: Left (Current) and Right (Total Duration)
                // Left text right-aligned 8 pixels to the left of the start point of the slider
                Positioned(
                  right: outerWidth - (center.dx - radius) - 12,
                  top: center.dy - 20,
                  child: Text(
                    _formatDuration(displayPosition),
                    style: const TextStyle(
                      color: MusicColors.titleColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                // Right text left-aligned 8 pixels to the right of the end point of the slider
                Positioned(
                  left: center.dx + radius - 12,
                  top: center.dy - 20,
                  child: Text(
                    _formatDuration(_duration),
                    style: const TextStyle(
                      color: MusicColors.titleColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildArtworkWidget(String? artworkPath, double size) {
    if (artworkPath != null) {
      final file = File(artworkPath);
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
}

class SemiCircularSliderPainter extends CustomPainter {
  final double progress;
  final Color trackColor;
  final Color progressColor;
  final Color thumbColor;
  final double radius;

  SemiCircularSliderPainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
    required this.thumbColor,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Draw track arc
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, pi, -pi, false, trackPaint);

    // Draw progress arc
    if (progress > 0) {
      final progressPaint = Paint()
        ..shader = LinearGradient(
          colors: [progressColor.withOpacity(0.5), progressColor],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ).createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6.0
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(rect, pi, -progress * pi, false, progressPaint);
    }

    // Draw thumb at current position
    final thumbAngle = pi - progress * pi;
    final thumbCenter = Offset(
      center.dx + radius * cos(thumbAngle),
      center.dy + radius * sin(thumbAngle),
    );

    // Draw outer thumb glow
    final thumbGlowPaint = Paint()
      ..color = progressColor.withOpacity(0.3)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(thumbCenter, 10.0, thumbGlowPaint);

    // Draw inner thumb
    final thumbPaint = Paint()
      ..color = thumbColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(thumbCenter, 6.0, thumbPaint);

    // Draw thumb border
    final thumbBorderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(thumbCenter, 6.0, thumbBorderPaint);
  }

  @override
  bool shouldRepaint(covariant SemiCircularSliderPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.progressColor != progressColor ||
        oldDelegate.thumbColor != thumbColor ||
        oldDelegate.radius != radius;
  }
}
