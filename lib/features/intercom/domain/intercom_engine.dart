import 'intercom_models.dart';

/// Single entry point for intercom audio orchestration.
///
/// The engine is responsible for:
/// - Picking a transport (P2P vs SFU) based on participant count.
/// - Applying strategic waiting + hysteresis policies.
/// - Managing mic state and reporting a single state stream for UI.
/// - Encapsulating signaling + media details behind a stable interface.
abstract class IntercomEngine {
  /// Engine state stream. UI can render from this without knowing underlying transport.
  Stream<IntercomState> get state$;

  /// Telemetry stream (dev overlay / analytics). Should not be used for UI logic.
  Stream<IntercomTelemetryEvent> get telemetry$;

  /// Last known state snapshot.
  IntercomState get snapshot;

  /// Starts internal resources/subscriptions.
  /// Idempotent.
  Future<void> start({
    IntercomPolicy policy = const IntercomPolicy(),
    IntercomStartOptions options = const IntercomStartOptions(),
  });

  /// Stops internal resources/subscriptions.
  /// Idempotent.
  Future<void> stop();

  /// Attaches/updates the current voice session context.
  ///
  /// Higher layers (e.g., VoiceSessionBloc) should call this whenever
  /// session details or participant list changes.
  Future<void> attachSession(IntercomSessionContext context);

  /// Detaches from current session.
  ///
  /// If [stopAudio] is true, the engine should stop transports and release audio focus.
  Future<void> detachSession({bool stopAudio = true});

  /// Sets mic enabled state.
  Future<void> setMicEnabled(bool enabled);

  /// Convenience helper.
  Future<void> toggleMic();

  /// Manual overrides (useful for debugging / ops). Implementations may choose
  /// to ignore these in production.
  Future<void> forceSwitchToP2p({String reason = 'manual'});
  Future<void> forceSwitchToSfu({String reason = 'manual'});

  /// Optional hooks.
  Future<void> onLifecycleChanged(IntercomLifecycleState state);
  Future<void> onConnectivityChanged({
    required bool online,
    String? networkType,
  });

  /// Notify engine that global audio settings (Noise Suppression, etc) have changed.
  Future<void> onAudioSettingsChanged();

  /// Releases resources permanently.
  Future<void> dispose();
}
