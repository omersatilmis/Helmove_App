import 'package:flutter/foundation.dart';

/// Stable error codes to support telemetry, UX messaging, and analytics.
enum IntercomFailureCode {
  unknown,
  permissionsDenied,
  signalrDisconnected,
  livekitTokenFailed,
  livekitConnectFailed,
  webrtcInitFailed,
  webrtcOfferFailed,
  webrtcAnswerFailed,
  webrtcIceFailed,
  transportSwitchFailed,
  reconnectTtlExceeded,
}

@immutable
class IntercomFailure {
  final IntercomFailureCode code;
  final String message;

  /// Original error/cause (not for UI).
  final Object? cause;
  final StackTrace? stackTrace;

  /// Whether the engine can/should keep trying without user action.
  final bool recoverable;

  const IntercomFailure({
    required this.code,
    required this.message,
    this.cause,
    this.stackTrace,
    this.recoverable = true,
  });

  @override
  String toString() {
    return 'IntercomFailure(code=$code, message=$message, recoverable=$recoverable, cause=$cause)';
  }
}
