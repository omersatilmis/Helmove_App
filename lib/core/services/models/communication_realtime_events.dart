import 'signalr_payloads.dart';

abstract class CommunicationRealtimeEvent {
  const CommunicationRealtimeEvent();
}

class RideTerminatedRealtimeEvent extends CommunicationRealtimeEvent {
  final int rideId;
  final int? sessionId;
  final int? version;
  const RideTerminatedRealtimeEvent({
    required this.rideId,
    this.sessionId,
    this.version,
  });
}

class RideCreatedRealtimeEvent extends CommunicationRealtimeEvent {
  final int rideId;
  final int? sessionId;
  final int? version;
  const RideCreatedRealtimeEvent({
    required this.rideId,
    this.sessionId,
    this.version,
  });
}

class UserJoinedVoiceSessionRealtimeEvent extends CommunicationRealtimeEvent {
  final String userId;
  final int sessionId;
  final int? version;
  const UserJoinedVoiceSessionRealtimeEvent({
    required this.userId,
    required this.sessionId,
    this.version,
  });
}

class UserLeftVoiceSessionRealtimeEvent extends CommunicationRealtimeEvent {
  final String userId;
  final int sessionId;
  final int? version;
  const UserLeftVoiceSessionRealtimeEvent({
    required this.userId,
    required this.sessionId,
    this.version,
  });
}

class UserDisconnectedVoiceSessionRealtimeEvent
    extends CommunicationRealtimeEvent {
  final String userId;
  final int sessionId;
  final int? version;
  const UserDisconnectedVoiceSessionRealtimeEvent({
    required this.userId,
    required this.sessionId,
    this.version,
  });
}

class HostChangedRealtimeEvent extends CommunicationRealtimeEvent {
  final Map<String, dynamic> data;
  const HostChangedRealtimeEvent(this.data);
}

class GroupRideUpdatedRealtimeEvent extends CommunicationRealtimeEvent {
  final int rideId;
  final int? sessionId;
  final int? version;
  const GroupRideUpdatedRealtimeEvent({
    required this.rideId,
    this.sessionId,
    this.version,
  });
}

class VoiceSessionRefreshRealtimeEvent extends CommunicationRealtimeEvent {
  final int sessionId;
  final int? rideId;
  final int? version;
  final String? reason;
  const VoiceSessionRefreshRealtimeEvent({
    required this.sessionId,
    this.rideId,
    this.version,
    this.reason,
  });
}

class UserForceRemovedRealtimeEvent extends CommunicationRealtimeEvent {
  final int sessionId;
  const UserForceRemovedRealtimeEvent(this.sessionId);
}

class ParticipantStatusUpdatedRealtimeEvent extends CommunicationRealtimeEvent {
  final ParticipantStatusPayload payload;
  const ParticipantStatusUpdatedRealtimeEvent(this.payload);
}

class UserMuteStateChangedRealtimeEvent extends CommunicationRealtimeEvent {
  final UserMuteStatePayload payload;
  const UserMuteStateChangedRealtimeEvent(this.payload);
}
