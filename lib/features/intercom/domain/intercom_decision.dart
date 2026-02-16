import 'package:flutter/foundation.dart';

import 'intercom_models.dart';

/// Why the engine chose a transport.
enum IntercomDecisionReason {
  /// Not enough participants to justify audio.
  idle,

  /// Exactly 2 participants, strategic waiting window started.
  awaitingSecondPartyStability,

  /// Exactly 2 participants and debounce expired: choose P2P.
  twoParticipantsP2p,

  /// 3+ participants: choose SFU.
  threeOrMoreParticipantsSfu,

  /// Manual override.
  manual,

  /// Recovering from a failure.
  recovery,
}

@immutable
class IntercomDecision {
  final IntercomTransport target;
  final IntercomDecisionReason reason;
  final int activeParticipantCount;

  /// Whether the decision waited for a policy delay.
  final Duration? delayApplied;

  final DateTime at;

  const IntercomDecision({
    required this.target,
    required this.reason,
    required this.activeParticipantCount,
    required this.at,
    this.delayApplied,
  });
}
