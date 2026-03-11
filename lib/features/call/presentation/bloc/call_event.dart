import 'package:equatable/equatable.dart';

abstract class CallEvent extends Equatable {
  const CallEvent();

  @override
  List<Object?> get props => [];
}

class CallRequested extends CallEvent {
  final int targetUserId;
  final String? targetDisplayName;

  const CallRequested({required this.targetUserId, this.targetDisplayName});

  @override
  List<Object?> get props => [targetUserId, targetDisplayName];
}

class CallAccepted extends CallEvent {
  const CallAccepted();
}

class CallRejected extends CallEvent {
  const CallRejected();
}

class CallHangUp extends CallEvent {
  const CallHangUp();
}

class CallToggleMicrophone extends CallEvent {
  const CallToggleMicrophone();
}

class CallIncomingReceived extends CallEvent {
  final int callerId;
  final String? callerDisplayName;
  final int? callId;

  const CallIncomingReceived({
    required this.callerId,
    this.callerDisplayName,
    this.callId,
  });

  @override
  List<Object?> get props => [callerId, callerDisplayName, callId];
}

class CallAcceptedByRemote extends CallEvent {
  final int targetUserId;

  const CallAcceptedByRemote({required this.targetUserId});

  @override
  List<Object?> get props => [targetUserId];
}

class CallRejectedByRemote extends CallEvent {
  final int targetUserId;
  final String? reason;

  const CallRejectedByRemote({required this.targetUserId, this.reason});

  @override
  List<Object?> get props => [targetUserId, reason];
}

class OfferReceived extends CallEvent {
  final int callerId;
  final String sdp;

  const OfferReceived({required this.callerId, required this.sdp});

  @override
  List<Object?> get props => [callerId, sdp];
}

class AnswerReceived extends CallEvent {
  final int targetUserId;
  final String sdp;

  const AnswerReceived({required this.targetUserId, required this.sdp});

  @override
  List<Object?> get props => [targetUserId, sdp];
}

class IceCandidateReceived extends CallEvent {
  final int fromUserId;
  final String candidate;
  final String? sdpMid;
  final int? sdpMLineIndex;

  const IceCandidateReceived({
    required this.fromUserId,
    required this.candidate,
    this.sdpMid,
    this.sdpMLineIndex,
  });

  @override
  List<Object?> get props => [fromUserId, candidate, sdpMid, sdpMLineIndex];
}

class CallEndedByRemote extends CallEvent {
  final int targetUserId;
  final int endedByUserId;

  const CallEndedByRemote({
    required this.targetUserId,
    required this.endedByUserId,
  });

  @override
  List<Object?> get props => [targetUserId, endedByUserId];
}

class CallConnectionStateChanged extends CallEvent {
  final String state;

  const CallConnectionStateChanged({required this.state});

  @override
  List<Object?> get props => [state];
}

class CallSignalingFailed extends CallEvent {
  final String message;

  const CallSignalingFailed({required this.message});

  @override
  List<Object?> get props => [message];
}

class CallOutgoingTimeoutReached extends CallEvent {
  const CallOutgoingTimeoutReached();
}

class CallConnectingTimeoutReached extends CallEvent {
  const CallConnectingTimeoutReached();
}

class CallDurationTicked extends CallEvent {
  const CallDurationTicked();
}

class CallAppResumedSyncRequested extends CallEvent {
  const CallAppResumedSyncRequested();
}
