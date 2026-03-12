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
  
  /// Kullanıcının şu anda bağlı olduğu aktif oturum ve tüm detayları/katılımcıları.
  /// BLoC bu alanı tek gerçeklik kaynağı (Source of Truth) olarak kullanır.
  /// Null ise kullanıcı hiçbir oturumda değildir.
  final VoiceSessionEntity? session;
  
  final List<VoiceSessionEntity>? mySessions;
  final RtcConnectionStatus rtcStatus;

  // LiveKit State
  final bool isLiveKitConnected;
  final bool isMicOn;
  final List<String> activeSpeakers;
  final String? liveKitError;
  final Map<int, IntercomConnectionQuality> participantQualities;

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
    VoiceSessionEntity? Function()? sessionOverride,
  }) {
    final newMySessions = mySessions ?? this.mySessions;

    // session senkronizasyonu:
    //   1. Eğer çağıran kod açıkça sessionOverride verdiyse onu kullan
    //   2. Eğer mySessions güncellendiyse (ve session null ise) listeden türet
    //   3. Hiçbiri yoksa mevcut değeri koru
    VoiceSessionEntity? resolvedSession;
    if (sessionOverride != null) {
      resolvedSession = sessionOverride();
    } else if (session != null) {
      resolvedSession = session;
    } else if (mySessions != null) {
      resolvedSession = _deriveActiveSessionFromList(newMySessions);
    } else {
      resolvedSession = this.session;
    }

    return VoiceSessionState(
      status: status ?? this.status,
      message: message,
      currentUserId: currentUserId ?? this.currentUserId,
      sessionId: sessionId ?? this.sessionId,
      session: resolvedSession,
      mySessions: newMySessions,
      isLiveKitConnected: isLiveKitConnected ?? this.isLiveKitConnected,
      isMicOn: isMicOn ?? this.isMicOn,
      activeSpeakers: activeSpeakers ?? this.activeSpeakers,
      liveKitError: liveKitError,
      rtcStatus: rtcStatus ?? this.rtcStatus,
      participantQualities: participantQualities ?? this.participantQualities,
    );
  }

  /// mySessions listesinden aktif oturumu türetir (tek yerden yönetim).
  static VoiceSessionEntity? _deriveActiveSessionFromList(
    List<VoiceSessionEntity>? sessions,
  ) {
    if (sessions == null || sessions.isEmpty) return null;
    for (final s in sessions) {
      // isActive true olan ilk session'ı "aktif" kabul et
      if (s.isActive) return s;
    }
    return null;
  }

  /// Aktif oturumdaki bağlı katılımcıları listeler.
  List<VoiceSessionParticipantEntity> get activeParticipants {
    if (session == null) return const [];
    return session!.participants
        .where(
          (p) =>
              p.status == 'Joined' ||
              p.status == 'Accepted' ||
              p.status == 'Disconnected' ||
              p.status == 'Invited',
        )
        .toList();
  }

  /// Mevcut kullanıcı için bekleyen davet sayısını döndürür.
  int get pendingInvitesCount {
    if (mySessions == null || currentUserId == null) return 0;
    return mySessions!
        .where(
          (s) => s.participants.any(
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
      ];
}
