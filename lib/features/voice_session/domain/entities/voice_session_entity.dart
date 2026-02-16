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
  final int? rideId;
  final int maxParticipants;
  final String? destination;
  final String? ridingStyle;
  final String? difficulty;
  final List<VoiceSessionParticipantEntity> participants;
  final int joinedCount;

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
    this.rideId,
    this.maxParticipants = 10,
    this.destination,
    this.ridingStyle,
    this.difficulty,
    required this.participants,
    this.joinedCount = 0,
  });

  VoiceSessionEntity copyWith({
    int? id,
    int? hostUserId,
    String? hostUsername,
    String? hostFirstName,
    String? hostLastName,
    String? hostProfileImage,
    String? title,
    String? roomName,
    bool? isActive,
    DateTime? createdAt,
    int? rideId,
    int? maxParticipants,
    String? destination,
    String? ridingStyle,
    String? difficulty,
    List<VoiceSessionParticipantEntity>? participants,
    int? joinedCount,
  }) {
    return VoiceSessionEntity(
      id: id ?? this.id,
      hostUserId: hostUserId ?? this.hostUserId,
      hostUsername: hostUsername ?? this.hostUsername,
      hostFirstName: hostFirstName ?? this.hostFirstName,
      hostLastName: hostLastName ?? this.hostLastName,
      hostProfileImage: hostProfileImage ?? this.hostProfileImage,
      title: title ?? this.title,
      roomName: roomName ?? this.roomName,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      rideId: rideId ?? this.rideId,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      destination: destination ?? this.destination,
      ridingStyle: ridingStyle ?? this.ridingStyle,
      difficulty: difficulty ?? this.difficulty,
      participants: participants ?? this.participants,
      joinedCount: joinedCount ?? this.joinedCount,
    );
  }

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
    rideId,
    participants,
  ];
}
