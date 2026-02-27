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

  /// iOS AVAudioSession.setActive durumunu takip eder.
  ///
  /// `true` iken OS bu uygulamanın sesi aktif kullandığını bilir ve
  /// arkaplan / sessizlik dönemlerinde audio session'ı suspend etmez.
  /// `false` iken iOS arka planda sesi kesebilir → call drop.
  bool _sessionActive = false;

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

  /// Müzik sesini kısar (Spotify, vb.) — sadece mode Auto/Always'de.
  Future<void> startDucking() async {
    if (_isDucking) return;
    if (_currentMixingMode == AudioMixingMode.off) return;
    // Ducking öncesi session aktif olmalı (iOS için zorunlu).
    await activateSession();
    _isDucking = true;
    AppLogger.info("AudioOrchestratorService: Ducking enabled");
  }

  /// Ducking bayrağını sıfırlar — audio session'ı KAPATMAZ.
  ///
  /// Önceki implementasyon burada `setActive(false)` çağırıyordu.
  /// Bu yanlıştı: sessizlik dönemlerinde (VAD tetiklemez) iOS audio
  /// session'ı devre dışı bırakıyordu → arkaplanda call drop.
  /// Session yalnızca `deactivateSession()` ile kapatılır.
  Future<void> stopDucking() async {
    if (!_isDucking) return;
    _isDucking = false;
    AppLogger.info("AudioOrchestratorService: Ducking disabled");
  }

  AudioMixingMode get currentMixingMode => _currentMixingMode;

  /// Ses oturumunu yönetir — transport başladığında / durduğunda çağrılır.
  ///
  /// `active = true`:
  ///   Her modda `activateSession()` çağrılır. Bu iOS için kritiktir:
  ///   AVAudioSession setActive(true) olmadan arka planda sessizlik
  ///   dönemlerinde (konuşma yok, VAD tetiklenmiyor) OS sesi keser.
  ///   `always` modunda ducking de hemen başlar.
  ///
  /// `active = false`:
  ///   Ses tamamen durduruluyorsa `deactivateSession()` çağrılır.
  Future<void> manageAudioFocus(bool active) async {
    if (active) {
      // Her modda session'ı aktifleştir (iOS arkaplan için zorunlu).
      await activateSession();
      // 'always' modunda ducking hemen başlar; 'auto' modunda VAD tetikler.
      if (_currentMixingMode == AudioMixingMode.always) {
        await startDucking();
      }
    } else {
      // Ses tamamen durduruluyor — session'ı kapat.
      await deactivateSession();
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Session Lifecycle
  // ─────────────────────────────────────────────────────────────────────────

  /// AVAudioSession'ı aktifleştirir (iOS) ve Android audio focus'u alır.
  ///
  /// Ducking modundan bağımsız — her zaman çağrılabilir.
  /// İdempotent: zaten aktifse tekrar setActive çağırmaz.
  Future<void> activateSession() async {
    if (_session == null || _sessionActive) return;
    try {
      await _session!.setActive(true);
      _sessionActive = true;
      AppLogger.info('AudioOrchestratorService: Audio session activated');
    } catch (e) {
      AppLogger.error('AudioOrchestratorService: Audio session activate failed', e);
    }
  }

  /// AVAudioSession'ı devre dışı bırakır (iOS) ve Android audio focus'u bırakır.
  ///
  /// YALNIZCA ses tamamen durduğunda çağrılır (`stop` / `detach` / `dispose`).
  /// Normal konuşma sessizliği, VAD yokluğu veya geçici kesintilerde çağrılmaz.
  Future<void> deactivateSession() async {
    if (_session == null) return;
    _isDucking = false;
    if (!_sessionActive) return;
    try {
      await _session!.setActive(false);
      _sessionActive = false;
      AppLogger.info('AudioOrchestratorService: Audio session deactivated');
    } catch (e) {
      AppLogger.error('AudioOrchestratorService: Audio session deactivate failed', e);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Interruption Stream
  // ─────────────────────────────────────────────────────────────────────────

  /// Telefon araması / Siri / alarm gibi sistem kesintileri için stream.
  ///
  /// `AudioInterruptionEvent.begin == true`  → kesinti başladı.
  /// `AudioInterruptionEvent.begin == false` → kesinti bitti.
  ///
  /// IntercomEngineImpl bu stream'e abone olarak kesintileri yönetir:
  /// başlayınca reconnecting state'e geçer, bitince session'ı yeniden
  /// aktifleştirip transport'u recovery modunda başlatır.
  Stream<AudioInterruptionEvent> get interruptionStream =>
      _session?.interruptionEventStream ?? const Stream.empty();

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
