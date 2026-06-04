import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

class VoiceMessagePlayer extends StatefulWidget {
  final String path;
  final Duration duration;
  final bool isMe;

  const VoiceMessagePlayer({
    super.key,
    required this.path,
    required this.duration,
    required this.isMe,
  });

  @override
  State<VoiceMessagePlayer> createState() => _VoiceMessagePlayerState();
}

class _VoiceMessagePlayerState extends State<VoiceMessagePlayer> {
  late final AudioPlayer _player;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<PlayerState>? _stateSub;

  Duration _position = Duration.zero;
  bool _playing = false;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _player.setVolume(1);
    _player.setReleaseMode(ReleaseMode.stop);
    _positionSub = _player.onPositionChanged.listen((value) {
      if (!mounted) return;
      setState(() => _position = value);
    });
    _stateSub = _player.onPlayerStateChanged.listen((state) {
      if (!mounted) return;
      setState(() => _playing = state == PlayerState.playing);
      if (state == PlayerState.completed) {
        setState(() => _position = Duration.zero);
      }
    });
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _stateSub?.cancel();
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final totalMs = widget.duration.inMilliseconds <= 0
        ? 1
        : widget.duration.inMilliseconds;
    final progress = (_position.inMilliseconds / totalMs).clamp(0.0, 1.0);
    final accent = widget.isMe ? cs.primary : cs.secondary;

    return SizedBox(
      width: 250,
      child: Row(
        children: [
          IconButton.filledTonal(
            tooltip: _playing ? 'Пауза' : 'Воспроизвести',
            onPressed: _toggle,
            icon: Icon(
              _playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LinearProgressIndicator(
                  value: progress,
                  minHeight: 4,
                  borderRadius: BorderRadius.circular(999),
                  backgroundColor: cs.onSurface.withValues(alpha: 0.10),
                  valueColor: AlwaysStoppedAnimation<Color>(accent),
                ),
                const SizedBox(height: 6),
                Text(
                  '${_format(_position)} / ${_format(widget.duration)}',
                  style: TextStyle(
                    color: cs.onSurface.withValues(alpha: 0.62),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggle() async {
    if (_playing) {
      await _player.pause();
      return;
    }
    if (_position >= widget.duration) {
      await _player.seek(Duration.zero);
    }
    if (!_loaded) {
      await _player.setSource(DeviceFileSource(widget.path));
      _loaded = true;
    }
    await _player.resume();
  }

  String _format(Duration value) {
    final minutes = value.inMinutes.remainder(60).toString();
    final seconds = value.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
