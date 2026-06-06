import 'dart:async';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

class VoicePlayer extends StatefulWidget {
  final String url;
  final int? durationSeconds;
  final Color foreground;
  final Color background;

  const VoicePlayer({
    super.key,
    required this.url,
    this.durationSeconds,
    required this.foreground,
    required this.background,
  });

  @override
  State<VoicePlayer> createState() => _VoicePlayerState();
}

class _VoicePlayerState extends State<VoicePlayer> {
  late final AudioPlayer _player;
  StreamSubscription<PlayerState>? _stateSub;
  StreamSubscription<Duration>? _posSub;
  bool _loaded = false;
  bool _loadError = false;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _stateSub = _player.playerStateStream.listen((state) {
      if (!mounted) return;
      if (state.processingState == ProcessingState.completed) {
        _player.seek(Duration.zero);
        _player.pause();
      }
      setState(() {});
    });
    _posSub = _player.positionStream.listen((pos) {
      if (!mounted) return;
      setState(() => _position = pos);
    });
  }

  @override
  void dispose() {
    _stateSub?.cancel();
    _posSub?.cancel();
    _player.dispose();
    super.dispose();
  }

  Future<void> _ensureLoaded() async {
    if (_loaded || _loadError) return;
    try {
      await _player.setUrl(widget.url);
      if (mounted) setState(() => _loaded = true);
    } catch (_) {
      if (mounted) setState(() => _loadError = true);
    }
  }

  String _fmt(Duration d) {
    final s = d.inSeconds;
    final m = (s ~/ 60).toString().padLeft(2, '0');
    final r = (s % 60).toString().padLeft(2, '0');
    return '$m:$r';
  }

  @override
  Widget build(BuildContext context) {
    final isPlaying = _player.playing;
    final total = _player.duration ??
        (widget.durationSeconds != null
            ? Duration(seconds: widget.durationSeconds!)
            : Duration.zero);
    final progress = total.inMilliseconds == 0
        ? 0.0
        : (_position.inMilliseconds / total.inMilliseconds).clamp(0.0, 1.0);
    final displayDur = _player.playing || _position > Duration.zero
        ? _position
        : total;

    return SizedBox(
      width: 220,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () async {
              if (_loadError) {
                _loadError = false;
                await _ensureLoaded();
                return;
              }
              if (!_loaded) {
                await _ensureLoaded();
                if (!_loaded) return;
              }
              if (isPlaying) {
                await _player.pause();
              } else {
                await _player.play();
              }
            },
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: widget.foreground.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _loadError
                    ? Icons.refresh_rounded
                    : (isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded),
                color: widget.foreground,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _StaticWaveform(color: widget.foreground, progress: progress),
                const SizedBox(height: 4),
                Text(
                  _fmt(displayDur),
                  style: TextStyle(
                    color: widget.foreground.withValues(alpha: 0.85),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StaticWaveform extends StatelessWidget {
  final Color color;
  final double progress;

  const _StaticWaveform({required this.color, required this.progress});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 26,
      child: CustomPaint(
        painter: _WavePainter(color: color, progress: progress),
        size: const Size.fromHeight(26),
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  final Color color;
  final double progress;

  // Static placeholder bars
  static const List<double> _heights = [
    0.3, 0.6, 0.9, 0.7, 0.4, 0.8, 1.0, 0.6, 0.3, 0.5,
    0.8, 0.9, 0.6, 0.4, 0.7, 0.9, 0.5, 0.3, 0.6, 0.8,
    0.7, 0.4, 0.6, 0.9, 0.5,
  ];

  _WavePainter({required this.color, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final barCount = _heights.length;
    final gap = 2.0;
    final barWidth = (size.width - gap * (barCount - 1)) / barCount;
    final playedColor = color;
    final unplayedColor = color.withValues(alpha: 0.35);
    final playedUntil = progress * size.width;

    double x = 0;
    for (int i = 0; i < barCount; i++) {
      final h = _heights[i] * size.height;
      final y = (size.height - h) / 2;
      final rect = Rect.fromLTWH(x, y, barWidth, h);
      final paint = Paint()
        ..color = (x + barWidth / 2) <= playedUntil ? playedColor : unplayedColor;
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(2)),
        paint,
      );
      x += barWidth + gap;
    }
  }

  @override
  bool shouldRepaint(_WavePainter old) =>
      old.progress != progress || old.color != color;
}
