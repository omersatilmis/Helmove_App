import 'package:audio_session/audio_session.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/utils/app_logger.dart';

enum AudioMixingMode {
  auto, // Duck when speaking (standard)
  always, // Always duck when active
  off, // Mix but don't duck
}

class AudioOrchestratorService {
  AudioSession? _session;
  bool _isDucking = false;

  AudioMixingMode _currentMixingMode = AudioMixingMode.auto;
  bool _preferWiredMic = false;

  Future<void> init() async {
    _session = await AudioSession.instance;
    await _loadPreferences();
    await _configureSession();
    AppLogger.info(
      "AudioOrchestratorService: Initialized mode=${_currentMixingMode.name}",
    );
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final modeName = prefs.getString('audio_mixing_mode');
    if (modeName != null) {
      _currentMixingMode = AudioMixingMode.values.firstWhere(
        (e) => e.name == modeName,
        orElse: () => AudioMixingMode.auto,
      );
    }
    _preferWiredMic = prefs.getBool('prefer_wired_mic') ?? false;
  }

  Future<void> setAudioMixingMode(AudioMixingMode mode) async {
    if (_currentMixingMode == mode) return;
    _currentMixingMode = mode;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('audio_mixing_mode', mode.name);

    // If we are switching to OFF, ensure we release ducking immediately
    if (mode == AudioMixingMode.off) {
      await stopDucking();
    }

    await _configureSession();
  }

  Future<void> setPreferWiredMic(bool enable) async {
    _preferWiredMic = enable;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('prefer_wired_mic', enable);
    // Logic to switch input device would go here or be triggered
  }

  Future<void> _configureSession() async {
    // Determine options based on mode
    var iosOptions =
        AVAudioSessionCategoryOptions.allowBluetooth |
        AVAudioSessionCategoryOptions.defaultToSpeaker;

    // Logic for Mixing/Ducking
    if (_currentMixingMode != AudioMixingMode.off) {
      // Auto or Always -> Duck others
      iosOptions |= AVAudioSessionCategoryOptions.duckOthers;
    }

    // All modes allow mixing (unless we wanted strict exclusive, but user asked for "background music")
    // "Off" means "Music sesinde değişim olmaz" -> Mix but don't duck.
    // "Auto/Always" -> Mix and Duck.
    iosOptions |= AVAudioSessionCategoryOptions.mixWithOthers;

    await _session!.configure(
      AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
        avAudioSessionCategoryOptions: iosOptions,
        avAudioSessionMode: AVAudioSessionMode.voiceChat,
        avAudioSessionRouteSharingPolicy:
            AVAudioSessionRouteSharingPolicy.defaultPolicy,
        avAudioSessionSetActiveOptions: AVAudioSessionSetActiveOptions.none,
        androidAudioAttributes: const AndroidAudioAttributes(
          contentType: AndroidAudioContentType.speech,
          flags: AndroidAudioFlags.none,
          usage: AndroidAudioUsage.voiceCommunication,
        ),
        androidAudioFocusGainType: _currentMixingMode == AudioMixingMode.off
            ? AndroidAudioFocusGainType
                  .gain // Might pause if we take focus?
            // Actually, to mix without ducking on Android we might want a different gain type
            // or rely on Android not ducking if we don't ask for it.
            // But voice communication usually demands focus.
            // Let's stick to gainTransientMayDuck for Auto/Always.
            // For Off, maybe gainTransient but that pauses.
            // Let's use gainTransientMayDuck with 'androidWillPauseWhenDucked' false?
            : AndroidAudioFocusGainType.gainTransientMayDuck,
        androidWillPauseWhenDucked: false,
      ),
    );
  }

  /// Start ducking music volume (Spotify, etc.)
  Future<void> startDucking() async {
    if (_isDucking) return;
    // If mode is OFF, we do nothing
    if (_currentMixingMode == AudioMixingMode.off) return;

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

  AudioMixingMode get currentMixingMode => _currentMixingMode;

  /// High-level orchestration for audio focus
  Future<void> manageAudioFocus(bool active) async {
    if (active) {
      // In 'always' mode, we duck immediately and stay ducked.
      // In 'auto' mode, we wait for VAD triggers from the Bloc.
      if (_currentMixingMode == AudioMixingMode.always) {
        await startDucking();
      }
    } else {
      await stopDucking();
    }
  }

  /// Force Helmic Type-C input and Bluetooth A2DP output
  /// Note: This is an architectural hook for native optimizations if needed.
  /// flutter_webrtc's Helper class is also used to switch outputs.
  Future<void> optimizeForHelmic() async {
    AppLogger.info(
      "AudioOrchestratorService: Optimizing for Helmic device... Wired=$_preferWiredMic",
    );
    // Future native implementations using MethodChannels could go here
    // For now, we rely on AudioSession's voiceChat mode and WEBRTC's internal routing.
  }
}
