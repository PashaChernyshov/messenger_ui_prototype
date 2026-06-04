import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoCirclePlayer extends StatefulWidget {
  final String path;
  final Duration duration;
  final bool isMe;
  final bool mirrorHorizontally;

  const VideoCirclePlayer({
    super.key,
    required this.path,
    required this.duration,
    required this.isMe,
    this.mirrorHorizontally = false,
  });

  @override
  State<VideoCirclePlayer> createState() => _VideoCirclePlayerState();
}

class _VideoCirclePlayerState extends State<VideoCirclePlayer> {
  late final VideoPlayerController _controller;
  bool _ready = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(File(widget.path))
      ..setLooping(false)
      ..setVolume(1)
      ..initialize().timeout(const Duration(seconds: 8)).then((_) {
        if (!mounted) return;
        setState(() => _ready = true);
      }).catchError((_) {
        if (!mounted) return;
        setState(() => _failed = true);
      });
    _controller.addListener(_onTick);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTick);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final accent = widget.isMe ? cs.primary : cs.secondary;

    return GestureDetector(
      onTap: _toggle,
      child: SizedBox(
        width: 190,
        height: 204,
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 188,
              height: 188,
              child: CircularProgressIndicator(
                value: _progress,
                strokeWidth: 4,
                backgroundColor: cs.onSurface.withValues(alpha: 0.10),
                valueColor: AlwaysStoppedAnimation<Color>(accent),
              ),
            ),
            Container(
              width: 178,
              height: 178,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: cs.surfaceContainerHighest,
              ),
              clipBehavior: Clip.antiAlias,
              child: _failed
                  ? _VideoError(duration: widget.duration)
                  : _ready
                      ? FittedBox(
                          fit: BoxFit.cover,
                          child: SizedBox(
                            width: _controller.value.size.width,
                            height: _controller.value.size.height,
                            child: Transform.flip(
                              flipX: widget.mirrorHorizontally,
                              child: VideoPlayer(_controller),
                            ),
                          ),
                        )
                      : const Center(
                          child: SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
            ),
            if (!_controller.value.isPlaying && !_failed)
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.42),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.play_arrow_rounded, size: 34),
              ),
            Positioned(
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.42),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  _format(_duration),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Duration get _duration {
    final actual = _controller.value.duration;
    if (actual.inMilliseconds > 0) return actual;
    return widget.duration;
  }

  double get _progress {
    final total = _duration.inMilliseconds;
    if (total <= 0) return 0;
    return (_controller.value.position.inMilliseconds / total).clamp(0.0, 1.0);
  }

  Future<void> _toggle() async {
    if (!_ready || _failed) return;
    if (_controller.value.isPlaying) {
      await _controller.pause();
      return;
    }
    if (_controller.value.position >= _duration) {
      await _controller.seekTo(Duration.zero);
    }
    await _controller.play();
  }

  void _onTick() {
    if (!mounted) return;
    setState(() {});
  }

  String _format(Duration value) {
    final minutes = value.inMinutes.remainder(60).toString();
    final seconds = value.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

class _VideoError extends StatelessWidget {
  final Duration duration;

  const _VideoError({required this.duration});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black26,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.videocam_off_rounded),
              const SizedBox(height: 8),
              Text(
                'Не удалось открыть видео',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
