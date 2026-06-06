import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

class RecordedVoice {
  final String filePath;
  final int durationSeconds;

  const RecordedVoice({required this.filePath, required this.durationSeconds});
}

const int kMaxRecordingSeconds = 120;

class VoiceRecorderController {
  final AudioRecorder _recorder = AudioRecorder();
  String? _currentPath;
  DateTime? _startedAt;

  Future<bool> ensurePermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  Future<String?> start() async {
    if (!await ensurePermission()) return null;
    if (await _recorder.isRecording()) return _currentPath;

    final dir = await getTemporaryDirectory();
    final path =
        '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        sampleRate: 44100,
        bitRate: 96000,
        numChannels: 1,
      ),
      path: path,
    );
    _currentPath = path;
    _startedAt = DateTime.now();
    return path;
  }

  Future<RecordedVoice?> stop() async {
    if (!await _recorder.isRecording()) return null;
    final path = await _recorder.stop();
    final started = _startedAt;
    _startedAt = null;
    final usedPath = path ?? _currentPath;
    _currentPath = null;
    if (usedPath == null || started == null) return null;
    final dur = DateTime.now().difference(started).inSeconds;
    return RecordedVoice(filePath: usedPath, durationSeconds: dur.clamp(1, kMaxRecordingSeconds));
  }

  Future<void> cancel() async {
    if (await _recorder.isRecording()) {
      await _recorder.stop();
    }
    final p = _currentPath;
    _currentPath = null;
    _startedAt = null;
    if (p != null) {
      try {
        await Future.delayed(const Duration(milliseconds: 50));
      } catch (_) {}
    }
  }

  Future<void> dispose() async {
    await _recorder.dispose();
  }
}

/// In-chat recording HUD shown above the input bar while recording.
class RecordingHud extends StatefulWidget {
  final DateTime startedAt;
  final VoidCallback onCancel;
  final VoidCallback onSend;
  final VoidCallback onMaxReached;

  const RecordingHud({
    super.key,
    required this.startedAt,
    required this.onCancel,
    required this.onSend,
    required this.onMaxReached,
  });

  @override
  State<RecordingHud> createState() => _RecordingHudState();
}

class _RecordingHudState extends State<RecordingHud> {
  Timer? _ticker;
  int _seconds = 0;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(milliseconds: 250), (_) {
      final s = DateTime.now().difference(widget.startedAt).inSeconds;
      if (s == _seconds) return;
      setState(() => _seconds = s);
      if (s >= kMaxRecordingSeconds) {
        HapticFeedback.mediumImpact();
        widget.onMaxReached();
      }
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  String _fmt(int s) {
    final m = (s ~/ 60).toString().padLeft(2, '0');
    final r = (s % 60).toString().padLeft(2, '0');
    return '$m:$r';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          _PulsingDot(color: Colors.redAccent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Kayıt... ${_fmt(_seconds)} / ${_fmt(kMaxRecordingSeconds)}',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
            tooltip: 'İptal',
            onPressed: widget.onCancel,
          ),
          IconButton(
            icon: Icon(Icons.send_rounded, color: color),
            tooltip: 'Gönder',
            onPressed: widget.onSend,
          ),
        ],
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  final Color color;
  const _PulsingDot({required this.color});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(begin: 0.3, end: 1.0).animate(_ctrl),
      child: Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: widget.color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
