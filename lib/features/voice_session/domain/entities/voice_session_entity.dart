import 'package:equatable/equatable.dart';
import 'voice_session_participant_entity.dart';

/// Sesli sohbet oturumu entity'si
/// adminId = Admin (sesli oturumun kurucusu/lideri) kullanıcı ID'si
class VoiceSessionEntity extends Equatable {
  final int id;
  final int adminId; // Admin ID (Backend field adı: hostUserId)
  final String? adminUsername;
  final String? adminFirstName;
  final String? adminLastName;
  final String? adminProfileImage;
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
    required this.adminId,
    this.adminUsername,
    this.adminFirstName,
    this.adminLastName,
    this.adminProfileImage,
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
    int? adminId,
    String? adminUsername,
    String? adminFirstName,
    String? adminLastName,
    String? adminProfileImage,
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
      adminId: adminId ?? this.adminId,
      adminUsername: adminUsername ?? this.adminUsername,
      adminFirstName: adminFirstName ?? this.adminFirstName,
      adminLastName: adminLastName ?? this.adminLastName,
      adminProfileImage: adminProfileImage ?? this.adminProfileImage,
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

  /// Admin'in (oturum liderinin) görünen adı
  String get adminDisplayName {
    if (adminFirstName != null && adminLastName != null) {
      return '$adminFirstName $adminLastName';
    }
    return adminUsername ?? 'Bilinmeyen';
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
    adminId,
    adminUsername,
    title,
    roomName,
    isActive,
    createdAt,
    rideId,
    participants,
  ];
}
