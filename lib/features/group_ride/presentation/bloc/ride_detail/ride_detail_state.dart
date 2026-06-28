import 'package:equatable/equatable.dart';

import 'package:helmove/features/attendance_management/domain/entities/participant_entity.dart';
import 'package:helmove/features/attendance_management/domain/entities/participation_status_entity.dart';
import 'package:helmove/features/group_ride/domain/entities/group_ride_entity.dart';

enum RideDetailStatus { initial, loading, success, failure }

/// [Tur Detayı] tek state. Detay + katılım durumu + katılımcı listesi + aksiyon
/// durumunu tutar. Snackbar gibi tek seferlik geri bildirimler [feedbackMessage]
/// + [feedbackSeq] ile taşınır (listenWhen seq karşılaştırır).
class RideDetailState extends Equatable {
  final RideDetailStatus status;
  final GroupRideEntity? ride;
  final ParticipationStatusEntity? participation;
  final List<ParticipantEntity> participants;
  final int? currentUserId;

  /// Yükleme hatası (tüm ekran error view).
  final String? error;

  /// join/leave/approve/reject sürerken buton kilidi.
  final bool actionInProgress;

  /// Tek seferlik snackbar mesajı.
  final String? feedbackMessage;
  final bool feedbackIsError;
  final int feedbackSeq;

  const RideDetailState({
    this.status = RideDetailStatus.initial,
    this.ride,
    this.participation,
    this.participants = const [],
    this.currentUserId,
    this.error,
    this.actionInProgress = false,
    this.feedbackMessage,
    this.feedbackIsError = false,
    this.feedbackSeq = 0,
  });

  // ── Türetilmiş yardımcılar ────────────────────────────────────────────────

  bool get isOrganizer =>
      ride != null && currentUserId != null && ride!.adminId == currentUserId;

  /// Mevcut kullanıcının katılımcı listesindeki kaydı (varsa). Liste, kişinin
  /// gerçek durumunu (Pending/Approved) taşıyan otoritedir.
  ParticipantEntity? get _myParticipant {
    final uid = currentUserId;
    if (uid == null) return null;
    for (final p in participants) {
      if (p.userId == uid) return p;
    }
    return null;
  }

  /// Pending | Approved | Rejected | None.
  ///
  /// Önce katılımcı listesindeki kayıt (otorite); o yoksa participation-status'a
  /// düşülür. Not: participation-status backend'de düz `bool` dönüyor (yalnız
  /// "katılıyor mu"), Pending'i Approved'dan ayıramadığı için tek başına
  /// "üye" sayılmaz — gerçek durum listeden okunur.
  String get myStatus => _myParticipant?.status ?? participation?.status ?? 'None';

  bool get isApprovedMember => !isOrganizer && myStatus == 'Approved';

  bool get isPending => !isOrganizer && myStatus == 'Pending';

  bool get isRejected => !isOrganizer && myStatus == 'Rejected';

  /// Henüz katılmamış / ilişkisiz kullanıcı.
  bool get canJoin =>
      !isOrganizer && !isApprovedMember && !isPending && !isRejected;

  List<ParticipantEntity> get pendingParticipants =>
      participants.where((p) => p.status == 'Pending').toList();

  List<ParticipantEntity> get approvedParticipants =>
      participants.where((p) => p.status == 'Approved').toList();

  RideDetailState copyWith({
    RideDetailStatus? status,
    GroupRideEntity? ride,
    ParticipationStatusEntity? participation,
    List<ParticipantEntity>? participants,
    int? currentUserId,
    String? error,
    bool? actionInProgress,
    String? feedbackMessage,
    bool? feedbackIsError,
    int? feedbackSeq,
  }) {
    return RideDetailState(
      status: status ?? this.status,
      ride: ride ?? this.ride,
      participation: participation ?? this.participation,
      participants: participants ?? this.participants,
      currentUserId: currentUserId ?? this.currentUserId,
      error: error,
      actionInProgress: actionInProgress ?? this.actionInProgress,
      feedbackMessage: feedbackMessage ?? this.feedbackMessage,
      feedbackIsError: feedbackIsError ?? this.feedbackIsError,
      feedbackSeq: feedbackSeq ?? this.feedbackSeq,
    );
  }

  @override
  List<Object?> get props => [
    status,
    ride,
    participation,
    participants,
    currentUserId,
    error,
    actionInProgress,
    feedbackMessage,
    feedbackIsError,
    feedbackSeq,
  ];
}
