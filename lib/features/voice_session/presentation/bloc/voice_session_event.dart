import 'package:equatable/equatable.dart';
import '../../data/dto/create_voice_session_request_dto.dart';
import '../../data/dto/invite_users_request_dto.dart';
import '../../../intercom/domain/intercom_models.dart';

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

  const GetVoiceSessionDetailsEvent(this.sessionId);

  @override
  List<Object?> get props => [sessionId];
}

/// Kullanıcının aktif session'larını getir
class GetMyVoiceSessionsEvent extends VoiceSessionEvent {
  const GetMyVoiceSessionsEvent();
}

/// Daveti kabul et
class AcceptVoiceSessionInviteEvent extends VoiceSessionEvent {
  final int sessionId;

  const AcceptVoiceSessionInviteEvent(this.sessionId);

  @override
  List<Object?> get props => [sessionId];
}

class VoiceSessionParticipantJoinedEvent extends VoiceSessionEvent {
  final String userId;
  final String? roomId;
  const VoiceSessionParticipantJoinedEvent(this.userId, {this.roomId});
  @override
  List<Object?> get props => [userId, roomId];
}

class VoiceSessionParticipantLeftEvent extends VoiceSessionEvent {
  final String userId;
  final String? roomId;
  const VoiceSessionParticipantLeftEvent(this.userId, {this.roomId});
  @override
  List<Object?> get props => [userId, roomId];
}

class VoiceSessionForceRemovedEvent extends VoiceSessionEvent {
  final int sessionId;
  final String? reason;

  const VoiceSessionForceRemovedEvent(this.sessionId, {this.reason});

  @override
  List<Object?> get props => [sessionId, reason];
}

class KickUserEvent extends VoiceSessionEvent {
  final int sessionId;
  final int targetUserId;
  const KickUserEvent(this.sessionId, this.targetUserId);
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

/// Mikrofon aç/kapat.
class ToggleMicrophoneEvent extends VoiceSessionEvent {
  const ToggleMicrophoneEvent();
}

/// Mikrofon durumu dışarıdan (service'den) değişti (internal event).
class LiveKitMicStateChangedEvent extends VoiceSessionEvent {
  final bool isEnabled;
  const LiveKitMicStateChangedEvent(this.isEnabled);
  @override
  List<Object?> get props => [isEnabled];
}

/// LiveKit bağlantı durumu değişti (internal event).
class LiveKitConnectionChangedEvent extends VoiceSessionEvent {
  final String connectionState; // connected, disconnected, reconnecting
  const LiveKitConnectionChangedEvent(this.connectionState);
  @override
  List<Object?> get props => [connectionState];
}

/// Aktif konuşmacılar değişti (internal event).
class ActiveSpeakersChangedEvent extends VoiceSessionEvent {
  final List<String> speakerIdentities;
  const ActiveSpeakersChangedEvent(this.speakerIdentities);
  @override
  List<Object?> get props => [speakerIdentities];
}

// ============================================================
// Headless P2P Events (RTC Orchestrator)
// ============================================================

class HandleHeadlessCallRequestEvent extends VoiceSessionEvent {
  final String callerId;
  const HandleHeadlessCallRequestEvent(this.callerId);
  @override
  List<Object?> get props => [callerId];
}

class HandleHeadlessCallAcceptedEvent extends VoiceSessionEvent {
  final String userId;
  const HandleHeadlessCallAcceptedEvent(this.userId);
  @override
  List<Object?> get props => [userId];
}

class HandleHeadlessCallEndedEvent extends VoiceSessionEvent {
  final String userId;
  const HandleHeadlessCallEndedEvent(this.userId);
  @override
  List<Object?> get props => [userId];
}

class HandleHeadlessOfferEvent extends VoiceSessionEvent {
  final String callerId;
  final String sdp;
  const HandleHeadlessOfferEvent(this.callerId, this.sdp);
  @override
  List<Object?> get props => [callerId, sdp];
}

class HandleHeadlessAnswerEvent extends VoiceSessionEvent {
  final String targetUserId;
  final String sdp;
  const HandleHeadlessAnswerEvent(this.targetUserId, this.sdp);
  @override
  List<Object?> get props => [targetUserId, sdp];
}

class HandleHeadlessIceCandidateEvent extends VoiceSessionEvent {
  final String fromUserId;
  final dynamic candidateData;
  const HandleHeadlessIceCandidateEvent(this.fromUserId, this.candidateData);
  @override
  List<Object?> get props => [fromUserId, candidateData];
}

/// Internal event: 5-second debounce timer expired for P2P/SFU decision.
/// Fired by the orchestrator after waiting to see if more participants join.
class RtcDebounceExpiredEvent extends VoiceSessionEvent {
  const RtcDebounceExpiredEvent();
}

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
