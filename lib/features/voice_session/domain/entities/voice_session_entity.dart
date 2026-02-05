import 'package:equatable/equatable.dart';
import 'voice_session_participant_entity.dart';

/// Sesli sohbet oturumu entity'si
class VoiceSessionEntity extends Equatable {
  final int id;
  final int hostUserId;
  final String? hostUsername;
  final String? hostFirstName;
  final String? hostLastName;
  final String? hostProfileImage;
  final String title;
  final String roomName;
  final bool isActive;
  final DateTime createdAt;
  final List<VoiceSessionParticipantEntity> participants;

  const VoiceSessionEntity({
    required this.id,
    required this.hostUserId,
    this.hostUsername,
    this.hostFirstName,
    this.hostLastName,
    this.hostProfileImage,
    required this.title,
    required this.roomName,
    required this.isActive,
    required this.createdAt,
    required this.participants,
  });

  /// Host'un görünen adı
  String get hostDisplayName {
    if (hostFirstName != null && hostLastName != null) {
      return '$hostFirstName $hostLastName';
    }
    return hostUsername ?? 'Bilinmeyen';
  }

  /// Aktif katılımcı sayısı (Joined, Accepted veya Disconnected status)
  /// Disconnected: Odada ama bağlantısı kopmuş olanlar da sayılır.
  int get activeParticipantCount {
    return participants
        .where(
          (p) =>
              p.status == 'Joined' ||
              p.status == 'Accepted' ||
              p.status == 'Disconnected',
        )
        .length;
  }

  @override
  List<Object?> get props => [
    id,
    hostUserId,
    hostUsername,
    title,
    roomName,
    isActive,
    createdAt,
    participants,
  ];
}
