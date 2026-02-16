import 'package:flutter/foundation.dart';

import '../../voice_session/domain/enums/rtc_state.dart';
import 'intercom_decision.dart';
import 'intercom_failure.dart';

/// Transport layer chosen by the engine.
/// - [p2p] uses WebRTC directly.
/// - [sfu] uses LiveKit (SFU).
enum IntercomTransport {
  none,
  p2p,
  sfu,
}

/// High-level phase of the engine.
/// This is UI/analytics friendly; it intentionally does not expose implementation details.
enum IntercomPhase {
  idle,
  evaluating,
  connecting,
  connected,
  switching,
  reconnecting,
  failed,
}

/// Lifecycle signal abstracted away from Flutter's AppLifecycleState.
/// This keeps the engine API stable and testable.
enum IntercomLifecycleState {
  resumed,
  inactive,
  paused,
  detached,
  hidden,
}

@immutable
class IntercomPolicy {
  /// When exactly 2 active participants are present, wait this long before starting P2P.
  /// If a 3rd participant joins during the window, engine should prefer SFU.
  final Duration p2pDecisionDelay;

  /// When SFU is connected and active participants drop to 2, wait this long
  /// before switching back to P2P (hysteresis).
  final Duration sfuToP2pDelay;

  /// Max time allowed to recover from connectivity loss / transport reconnect.
  /// After this TTL, engine transitions to failed/idle and expects higher layers
  /// (server TTL/presence) to drop the user from the session.
  final Duration reconnectTtl;

  /// Debounce window for rapid participant churn.
  /// Kept small by default; can be tuned per environment.
  final Duration participantChurnDebounce;

  const IntercomPolicy({
    this.p2pDecisionDelay = const Duration(seconds: 5),
    this.sfuToP2pDelay = const Duration(seconds: 10),
    this.reconnectTtl = const Duration(seconds: 60),
    this.participantChurnDebounce = const Duration(milliseconds: 350),
  });
}

@immutable
class IntercomStartOptions {
  /// Emit telemetry events (dev overlay / analytics).
  final bool telemetryEnabled;

  /// Allow manual overrides like forceSwitchToP2p/Sfu.
  /// Implementations may still ignore these in release builds.
  final bool manualOverridesEnabled;

  const IntercomStartOptions({
    this.telemetryEnabled = true,
    this.manualOverridesEnabled = true,
  });
}

@immutable
class IntercomParticipant {
  final int userId;
  final String? displayName;
  final bool isLocal;
  final bool isSpeaking;

  const IntercomParticipant({
    required this.userId,
    this.displayName,
    required this.isLocal,
    this.isSpeaking = false,
  });
}

/// Minimal context required by the engine to orchestrate transports.
///
/// This is intentionally decoupled from VoiceSessionEntity to avoid a hard domain dependency.
@immutable
class IntercomSessionContext {
  final int sessionId;
  final String roomName;
  final int hostUserId;
  final int localUserId;

  /// Active participant user IDs (should already be filtered for relevant statuses).
  /// Should include local user ID.
  final List<int> activeParticipantUserIds;

  /// Optional mapping for UI convenience (display name, speaking state, etc).
  /// If omitted, engine still functions.
  final List<IntercomParticipant>? participants;

  const IntercomSessionContext({
    required this.sessionId,
    required this.roomName,
    required this.hostUserId,
    required this.localUserId,
    required this.activeParticipantUserIds,
    this.participants,
  });

  int get activeCount => activeParticipantUserIds.length;
}

@immutable
class IntercomState {
  final IntercomPhase phase;
  final IntercomTransport transport;

  /// Reuses existing enum to avoid duplicating connection semantics.
  final RtcConnectionStatus rtcStatus;

  final bool micEnabled;

  /// Active speaker identities/userIds (best-effort).
  ///
  /// Current UI expects speaker ids as strings matching participant userId.
  final List<String> activeSpeakerIds;

  /// Best-effort participants snapshot.
  final List<IntercomParticipant> participants;

  final Object? lastError;
  final IntercomFailure? lastFailure;
  final IntercomDecision? lastDecision;
  final DateTime updatedAt;

  const IntercomState({
    required this.phase,
    required this.transport,
    required this.rtcStatus,
    required this.micEnabled,
    required this.activeSpeakerIds,
    required this.participants,
    required this.updatedAt,
    this.lastError,
    this.lastFailure,
    this.lastDecision,
  });

  IntercomState copyWith({
    IntercomPhase? phase,
    IntercomTransport? transport,
    RtcConnectionStatus? rtcStatus,
    bool? micEnabled,
    List<String>? activeSpeakerIds,
    List<IntercomParticipant>? participants,
    Object? lastError,
    IntercomFailure? lastFailure,
    IntercomDecision? lastDecision,
    bool clearError = false,
    DateTime? updatedAt,
  }) {
    return IntercomState(
      phase: phase ?? this.phase,
      transport: transport ?? this.transport,
      rtcStatus: rtcStatus ?? this.rtcStatus,
      micEnabled: micEnabled ?? this.micEnabled,
      activeSpeakerIds: activeSpeakerIds ?? this.activeSpeakerIds,
      participants: participants ?? this.participants,
      updatedAt: updatedAt ?? DateTime.now(),
      lastError: clearError ? null : (lastError ?? this.lastError),
      lastFailure: lastFailure ?? this.lastFailure,
      lastDecision: lastDecision ?? this.lastDecision,
    );
  }

  static IntercomState initial() {
    return IntercomState(
      phase: IntercomPhase.idle,
      transport: IntercomTransport.none,
      rtcStatus: RtcConnectionStatus.disconnected,
      micEnabled: true,
      activeSpeakerIds: const <String>[],
      participants: const <IntercomParticipant>[],
      updatedAt: DateTime.fromMillisecondsSinceEpoch(0),
      lastError: null,
      lastFailure: null,
      lastDecision: null,
    );
  }

  int get participantCount => participants.length;
}

enum IntercomCommand {
  start,
  stop,
  attachSession,
  detachSession,
  setMicEnabled,
  toggleMic,
  forceSwitchToP2p,
  forceSwitchToSfu,
  stopAll,
  onLifecycleChanged,
  onConnectivityChanged,
}

/// Canonical telemetry event names.
///
/// Keep these stable; they are meant for logs/analytics and debug overlays.
abstract final class IntercomTelemetryNames {
  static const String engineStarted = 'engine.started';
  static const String engineStopped = 'engine.stopped';

  static const String sessionAttached = 'session.attached';
  static const String sessionDetached = 'session.detached';

  static const String transportEvaluated = 'transport.evaluated';
  static const String transportDecision = 'transport.decision';
  static const String transportSwitchStarted = 'transport.switch.started';
  static const String transportSwitchSucceeded = 'transport.switch.succeeded';
  static const String transportSwitchFailed = 'transport.switch.failed';

  static const String reconnectStarted = 'reconnect.started';
  static const String reconnectAttempt = 'reconnect.attempt';
  static const String reconnectRecovered = 'reconnect.recovered';
  static const String reconnectExpired = 'reconnect.expired';

  static const String micChanged = 'mic.changed';
  static const String activeSpeakersChanged = 'active_speakers.changed';

  static const String failure = 'failure';
}

/// Canonical telemetry payload keys.
abstract final class IntercomTelemetryKeys {
  static const String sessionId = 'sessionId';
  static const String roomName = 'roomName';
  static const String localUserId = 'localUserId';
  static const String hostUserId = 'hostUserId';

  static const String activeParticipantCount = 'activeParticipantCount';
  static const String activeParticipantUserIds = 'activeParticipantUserIds';

  static const String fromTransport = 'fromTransport';
  static const String toTransport = 'toTransport';
  static const String decisionReason = 'decisionReason';
  static const String delayMs = 'delayMs';
  static const String durationMs = 'durationMs';

  static const String micEnabled = 'micEnabled';
  static const String activeSpeakerIds = 'activeSpeakerIds';

  static const String failureCode = 'failureCode';
  static const String failureMessage = 'failureMessage';
  static const String recoverable = 'recoverable';
  static const String retryAttempt = 'retryAttempt';
}

enum IntercomTelemetryLevel {
  debug,
  info,
  warning,
  error,
}

@immutable
class IntercomTelemetryEvent {
  final IntercomTelemetryLevel level;
  final IntercomCommand command;
  final String name;
  final Map<String, Object?> data;
  final DateTime at;

  const IntercomTelemetryEvent({
    this.level = IntercomTelemetryLevel.info,
    required this.command,
    required this.name,
    required this.data,
    required this.at,
  });

  factory IntercomTelemetryEvent.now({
    IntercomTelemetryLevel level = IntercomTelemetryLevel.info,
    required IntercomCommand command,
    required String name,
    Map<String, Object?> data = const <String, Object?>{},
  }) {
    return IntercomTelemetryEvent(
      level: level,
      command: command,
      name: name,
      data: data,
      at: DateTime.now(),
    );
  }
}
