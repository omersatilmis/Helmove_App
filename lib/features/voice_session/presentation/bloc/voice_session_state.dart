import 'package:equatable/equatable.dart';
import '../../../intercom/domain/intercom_models.dart';
import '../../domain/entities/voice_session_entity.dart';
import '../../domain/entities/voice_session_participant_entity.dart';
import '../../domain/enums/rtc_state.dart';

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
  ended,
  kicked,
  preJoinError,
}

class VoiceSessionState extends Equatable {
  final VoiceSessionStatus status;
  final String? message;
  final int? currentUserId;
  final int? sessionId; // For Created, Left, InviteAccepted
  final VoiceSessionEntity? session;
  final List<VoiceSessionEntity>? mySessions;
  final RtcConnectionStatus rtcStatus;

  // LiveKit State
  final bool isLiveKitConnected;
  final bool isMicOn;
  final List<String> activeSpeakers;
  final String? liveKitError;
  final Map<int, IntercomConnectionQuality> participantQualities;

  /// Kullanıcının şu anda bağlı olduğu tek aktif oturum.
  /// BLoC tarafından mySessions her güncellendiğinde otomatik ayarlanır.
  /// UI bu alanı doğrudan okur — hesaplama gerekmez.
  final VoiceSessionEntity? activeSession;

  const VoiceSessionState({
    this.status = VoiceSessionStatus.initial,
    this.message,
    this.currentUserId,
    this.sessionId,
    this.session,
    this.mySessions,
    this.isLiveKitConnected = false,
    this.isMicOn = true,
    this.activeSpeakers = const [],
    this.liveKitError,
    this.rtcStatus = RtcConnectionStatus.disconnected,
    this.participantQualities = const {},
    this.activeSession,
  });

  VoiceSessionState copyWith({
    VoiceSessionStatus? status,
    String? message,
    int? currentUserId,
    int? sessionId,
    VoiceSessionEntity? session,
    List<VoiceSessionEntity>? mySessions,
    bool? isLiveKitConnected,
    bool? isMicOn,
    List<String>? activeSpeakers,
    String? liveKitError,
    RtcConnectionStatus? rtcStatus,
    Map<int, IntercomConnectionQuality>? participantQualities,
    VoiceSessionEntity? Function()? activeSessionOverride,
  }) {
    final newMySessions = mySessions ?? this.mySessions;

    // activeSession senkronizasyonu:
    //   1. Eğer çağıran kod açıkça activeSessionOverride verdiyse onu kullan
    //   2. Eğer mySessions güncellendiyse yeni listeden otomatik türet
    //   3. Hiçbiri yoksa mevcut değeri koru
    final VoiceSessionEntity? resolvedActiveSession;
    if (activeSessionOverride != null) {
      resolvedActiveSession = activeSessionOverride();
    } else if (mySessions != null) {
      resolvedActiveSession = _deriveActiveSession(newMySessions);
    } else {
      resolvedActiveSession = activeSession;
    }

    return VoiceSessionState(
      status: status ?? this.status,
      message: message, // Transient, usually overridden or null
      currentUserId: currentUserId ?? this.currentUserId,
      sessionId: sessionId ?? this.sessionId,
      session: session ?? this.session,
      mySessions: newMySessions,
      isLiveKitConnected: isLiveKitConnected ?? this.isLiveKitConnected,
      isMicOn: isMicOn ?? this.isMicOn,
      activeSpeakers: activeSpeakers ?? this.activeSpeakers,
      liveKitError: liveKitError, // Transient
      rtcStatus: rtcStatus ?? this.rtcStatus,
      participantQualities: participantQualities ?? this.participantQualities,
      activeSession: resolvedActiveSession,
    );
  }

  /// mySessions listesinden aktif oturumu türetir (tek yerden yönetim).
  static VoiceSessionEntity? _deriveActiveSession(
    List<VoiceSessionEntity>? sessions,
  ) {
    if (sessions == null || sessions.isEmpty) return null;
    for (final s in sessions) {
      if (s.isActive) return s;
    }
    return null;
  }

  /// Aktif oturumdaki bağlı katılımcıları listeler.
  List<VoiceSessionParticipantEntity> get activeParticipants {
    if (activeSession == null) return const [];
    return activeSession!.participants
        .where(
          (p) =>
              p.status == 'Joined' ||
              p.status == 'Accepted' ||
              p.status == 'Disconnected',
        )
        .toList();
  }

  /// Mevcut kullanıcı için bekleyen davet sayısını döndürür.
  int get pendingInvitesCount {
    if (mySessions == null || currentUserId == null) return 0;
    return mySessions!
        .where(
          (session) => session.participants.any(
            (p) => p.userId == currentUserId && p.status == 'Invited',
          ),
        )
        .length;
  }

  @override
  List<Object?> get props => [
    status,
    message,
    currentUserId,
    sessionId,
    session,
    mySessions,
    isLiveKitConnected,
    isMicOn,
    activeSpeakers,
    liveKitError,
    rtcStatus,
    participantQualities,
    activeSession,
  ];
}
