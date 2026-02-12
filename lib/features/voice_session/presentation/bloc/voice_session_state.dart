import 'package:equatable/equatable.dart';

enum VoiceSessionStatus {
  initial,
  loading,
  created,
  joined,
  left,
  error,
  detailsLoaded,
  mySessionsLoaded,
  inviteAccepted,
  inviteSent,
}

class VoiceSessionState extends Equatable {
  final VoiceSessionStatus status;
  final String? message;
  final int? sessionId; // For Created, Left, InviteAccepted
  final dynamic session; // VoiceSessionEntity (DetailsLoaded)
  final List<dynamic>?
  mySessions; // List<VoiceSessionEntity> (MySessionsLoaded)

  // LiveKit State
  final bool isLiveKitConnected;
  final bool isMicOn;
  final List<String> activeSpeakers;
  final String? liveKitError;

  const VoiceSessionState({
    this.status = VoiceSessionStatus.initial,
    this.message,
    this.sessionId,
    this.session,
    this.mySessions,
    this.isLiveKitConnected = false,
    this.isMicOn = true,
    this.activeSpeakers = const [],
    this.liveKitError,
  });

  VoiceSessionState copyWith({
    VoiceSessionStatus? status,
    String? message,
    int? sessionId,
    dynamic session,
    List<dynamic>? mySessions,
    bool? isLiveKitConnected,
    bool? isMicOn,
    List<String>? activeSpeakers,
    String? liveKitError,
  }) {
    return VoiceSessionState(
      status: status ?? this.status,
      message: message, // Message is transient, usually overridden or null
      sessionId: sessionId ?? this.sessionId,
      session: session ?? this.session, // Persist session details
      mySessions: mySessions ?? this.mySessions,
      isLiveKitConnected: isLiveKitConnected ?? this.isLiveKitConnected,
      isMicOn: isMicOn ?? this.isMicOn,
      activeSpeakers: activeSpeakers ?? this.activeSpeakers,
      liveKitError: liveKitError, // Error is transient
    );
  }

  @override
  List<Object?> get props => [
    status,
    message,
    sessionId,
    session,
    mySessions,
    isLiveKitConnected,
    isMicOn,
    activeSpeakers,
    liveKitError,
  ];
}
