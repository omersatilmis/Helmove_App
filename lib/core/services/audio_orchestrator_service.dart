import 'package:audio_session/audio_session.dart';
import '../../core/utils/app_logger.dart';

class AudioOrchestratorService {
  AudioSession? _session;
  bool _isDucking = false;

  Future<void> init() async {
    _session = await AudioSession.instance;
    await _session!.configure(
      AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
        avAudioSessionCategoryOptions:
            AVAudioSessionCategoryOptions.allowBluetooth |
            AVAudioSessionCategoryOptions.defaultToSpeaker,
        avAudioSessionMode: AVAudioSessionMode.voiceChat,
        avAudioSessionRouteSharingPolicy:
            AVAudioSessionRouteSharingPolicy.defaultPolicy,
        avAudioSessionSetActiveOptions: AVAudioSessionSetActiveOptions.none,
        androidAudioAttributes: const AndroidAudioAttributes(
          contentType: AndroidAudioContentType.speech,
          flags: AndroidAudioFlags.none,
          usage: AndroidAudioUsage.voiceCommunication,
        ),
        androidAudioFocusGainType:
            AndroidAudioFocusGainType.gainTransientMayDuck,
        androidWillPauseWhenDucked: false,
      ),
    );
    AppLogger.info("AudioOrchestratorService: Initialized");
  }

  /// Start ducking music volume (Spotify, etc.)
  Future<void> startDucking() async {
    if (_isDucking) return;
    try {
      final success = await _session!.setActive(true);
      if (success) {
        _isDucking = true;
        AppLogger.info("AudioOrchestratorService: Ducking enabled");
      }
    } catch (e) {
      AppLogger.error("AudioOrchestratorService: Ducking failed", e);
    }
  }

  /// Stop ducking and restore music volume
  Future<void> stopDucking() async {
    if (!_isDucking) return;
    try {
      await _session!.setActive(false);
      _isDucking = false;
      AppLogger.info("AudioOrchestratorService: Ducking disabled");
    } catch (e) {
      AppLogger.error("AudioOrchestratorService: Ducking stop failed", e);
    }
  }

  /// High-level orchestration for audio focus
  Future<void> manageAudioFocus(bool active) async {
    if (active) {
      await startDucking();
    } else {
      await stopDucking();
    }
  }

  /// Force Helmic Type-C input and Bluetooth A2DP output
  /// Note: This is an architectural hook for native optimizations if needed.
  /// flutter_webrtc's Helper class is also used to switch outputs.
  Future<void> optimizeForHelmic() async {
    AppLogger.info("AudioOrchestratorService: Optimizing for Helmic device...");
    // Future native implementations using MethodChannels could go here
    // For now, we rely on AudioSession's voiceChat mode and WEBRTC's internal routing.
  }
}
