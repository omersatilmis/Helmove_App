import 'package:equatable/equatable.dart';
import '../../data/dto/create_voice_session_request_dto.dart';
import '../../data/dto/invite_users_request_dto.dart';
import '../../../intercom/domain/intercom_models.dart';
import '../../../../core/services/models/signalr_payloads.dart';

abstract class VoiceSessionEvent extends Equatable {
  const VoiceSessionEvent();

  @override
  List<Object?> get props => [];
}

class CreateVoiceSessionEvent extends VoiceSessionEvent {
  final CreateVoiceSessionRequestDto request;

  const CreateVoiceSessionEvent(this.request);

  @override
  List<Object?> get props => [request];
}

class JoinVoiceSessionEvent extends VoiceSessionEvent {
  final int sessionId;

  const JoinVoiceSessionEvent(this.sessionId);

  @override
  List<Object?> get props => [sessionId];
}

class LeaveVoiceSessionEvent extends VoiceSessionEvent {
  final int sessionId;

  const LeaveVoiceSessionEvent(this.sessionId);

  @override
  List<Object?> get props => [sessionId];
}

class EndVoiceSessionEvent extends VoiceSessionEvent {
  final int sessionId;

  const EndVoiceSessionEvent(this.sessionId);

  @override
  List<Object?> get props => [sessionId];
}

class TeardownVoiceSessionLocalEvent extends VoiceSessionEvent {
  final int? sessionId;

  const TeardownVoiceSessionLocalEvent({this.sessionId});

  @override
  List<Object?> get props => [sessionId];
}

class InviteUsersEvent extends VoiceSessionEvent {
  final int sessionId;
  final InviteUsersRequestDto request;

  const InviteUsersEvent(this.sessionId, this.request);

  @override
  List<Object?> get props => [sessionId, request];
}

/// Belirli bir session'ın detaylarını getir
class GetVoiceSessionDetailsEvent extends VoiceSessionEvent {
  final int sessionId;
  final bool force;

  const GetVoiceSessionDetailsEvent(this.sessionId, {this.force = false});

  @override
  List<Object?> get props => [sessionId, force];
}

/// Kullanıcının aktif session'larını getir
class GetMyVoiceSessionsEvent extends VoiceSessionEvent {
  final bool force;

  const GetMyVoiceSessionsEvent({this.force = false});

  @override
  List<Object?> get props => [force];
}

/// Daveti kabul et
class AcceptVoiceSessionInviteEvent extends VoiceSessionEvent {
  final int sessionId;

  const AcceptVoiceSessionInviteEvent(this.sessionId);

  @override
  List<Object?> get props => [sessionId];
}

class VoiceSessionForceRemovedEvent extends VoiceSessionEvent {
  final int sessionId;
  final String? reason;

  const VoiceSessionForceRemovedEvent(this.sessionId, {this.reason});

  @override
  List<Object?> get props => [sessionId, reason];
}

class RideTerminatedVoiceSessionEvent extends VoiceSessionEvent {
  final String? rideId;

  const RideTerminatedVoiceSessionEvent(this.rideId);

  @override
  List<Object?> get props => [rideId];
}

class VoiceSessionMembershipDeltaEvent extends VoiceSessionEvent {
  final int sessionId;
  final String userId;

  /// Target status: 'Joined', 'Left', or 'Disconnected'.
  final String nextStatus;
  final int? version;

  const VoiceSessionMembershipDeltaEvent({
    required this.sessionId,
    required this.userId,
    required this.nextStatus,
    this.version,
  });

  @override
  List<Object?> get props => [sessionId, userId, nextStatus, version];
}

class KickUserEvent extends VoiceSessionEvent {
  final int sessionId;
  final int targetUserId;
  const KickUserEvent(this.sessionId, this.targetUserId);
  @override
  List<Object?> get props => [sessionId, targetUserId];
}

class KickParticipantEvent extends VoiceSessionEvent {
  final int rideId;
  final int targetUserId;
  const KickParticipantEvent(this.rideId, this.targetUserId);
  @override
  List<Object?> get props => [rideId, targetUserId];
}

class PromoteParticipantEvent extends VoiceSessionEvent {
  final int sessionId;
  final int targetUserId;
  const PromoteParticipantEvent(this.sessionId, this.targetUserId);
  @override
  List<Object?> get props => [sessionId, targetUserId];
}

class DemoteParticipantEvent extends VoiceSessionEvent {
  final int sessionId;
  final int targetUserId;
  const DemoteParticipantEvent(this.sessionId, this.targetUserId);
  @override
  List<Object?> get props => [sessionId, targetUserId];
}

class MuteUserEvent extends VoiceSessionEvent {
  final int sessionId;
  final int targetUserId;
  const MuteUserEvent(this.sessionId, this.targetUserId);
  @override
  List<Object?> get props => [sessionId, targetUserId];
}

class TransferHostEvent extends VoiceSessionEvent {
  final int sessionId;
  final int newHostId;
  const TransferHostEvent(this.sessionId, this.newHostId);
  @override
  List<Object?> get props => [sessionId, newHostId];
}

class VoiceSessionHostChanged extends VoiceSessionEvent {
  final Map<String, dynamic> data;
  const VoiceSessionHostChanged(this.data);
  @override
  List<Object?> get props => [data];
}

// ============================================================
// LiveKit SFU Events (Faz 3)
// ============================================================

/// LiveKit room'a bağlan (token al + room.connect).
/// [roomName] — VoiceSessionEntity.roomName
class ConnectToLiveKitEvent extends VoiceSessionEvent {
  final String roomName;
  final String? displayName;
  const ConnectToLiveKitEvent(this.roomName, {this.displayName});
  @override
  List<Object?> get props => [roomName, displayName];
}

/// LiveKit room'dan bağlantıyı kes.
class DisconnectFromLiveKitEvent extends VoiceSessionEvent {
  const DisconnectFromLiveKitEvent();
}

/// Toggle microphone.
class ToggleMicrophoneEvent extends VoiceSessionEvent {
  const ToggleMicrophoneEvent();
}

/// Internal event: app session current user changed.
class AppSessionCurrentUserChangedEvent extends VoiceSessionEvent {
  final int? userId;
  const AppSessionCurrentUserChangedEvent(this.userId);

  @override
  List<Object?> get props => [userId];
}

class IntercomStateChangedEvent extends VoiceSessionEvent {
  final IntercomState intercomState;

  const IntercomStateChangedEvent(this.intercomState);

  @override
  List<Object?> get props => [intercomState];
}

class ParticipantStatusUpdatedEvent extends VoiceSessionEvent {
  final ParticipantStatusPayload payload;
  const ParticipantStatusUpdatedEvent(this.payload);
  @override
  List<Object?> get props => [
    payload.userId,
    payload.phoneBatteryLevel,
    payload.intercomBatteryLevel,
    payload.signalStrength,
    payload.isRemoteMuted,
  ];
}

class UserMuteStateChangedEvent extends VoiceSessionEvent {
  final UserMuteStatePayload payload;
  const UserMuteStateChangedEvent(this.payload);

  @override
  List<Object?> get props => [
    payload.targetUserId,
    payload.isMuted,
    payload.mutedByUserId,
  ];
}

class ClearSessionDataEvent extends VoiceSessionEvent {
  const ClearSessionDataEvent();
}

class VoiceSessionNotFoundDetectedEvent extends VoiceSessionEvent {
  final String message;
  const VoiceSessionNotFoundDetectedEvent(this.message);

  @override
  List<Object?> get props => [message];
}
