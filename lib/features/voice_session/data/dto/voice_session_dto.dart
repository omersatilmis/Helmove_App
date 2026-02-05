import '../../domain/entities/voice_session_entity.dart';
import 'voice_session_participant_dto.dart';

/// Backend'den gelen SessionDto'yu parse eden DTO
class VoiceSessionDto {
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
  final List<VoiceSessionParticipantDto> participants;

  VoiceSessionDto({
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

  factory VoiceSessionDto.fromJson(Map<String, dynamic> json) {
    // Backend response structure:
    // { id, hostUserId, host: { id, username, firstName, lastName, profilePictureUrl },
    //   title, roomName, isActive, createdAt, participants: [...] }

    // Handle nested 'data' wrapper if present
    final data = json.containsKey('data') ? json['data'] : json;

    final host = data['host'] as Map<String, dynamic>?;
    final participantsList =
        (data['participants'] as List<dynamic>?)
            ?.map((p) => VoiceSessionParticipantDto.fromJson(p))
            .toList() ??
        [];

    return VoiceSessionDto(
      id: data['id'] ?? 0,
      hostUserId: data['hostUserId'] ?? 0,
      hostUsername: host?['username'],
      hostFirstName: host?['firstName'],
      hostLastName: host?['lastName'],
      hostProfileImage: host?['profilePictureUrl'],
      title: data['title'] ?? '',
      roomName: data['roomName'] ?? '',
      isActive: data['isActive'] ?? true,
      createdAt: data['createdAt'] != null
          ? DateTime.tryParse(data['createdAt']) ?? DateTime.now()
          : DateTime.now(),
      participants: participantsList,
    );
  }

  VoiceSessionEntity toEntity() {
    return VoiceSessionEntity(
      id: id,
      hostUserId: hostUserId,
      hostUsername: hostUsername,
      hostFirstName: hostFirstName,
      hostLastName: hostLastName,
      hostProfileImage: hostProfileImage,
      title: title,
      roomName: roomName,
      isActive: isActive,
      createdAt: createdAt,
      participants: participants.map((p) => p.toEntity()).toList(),
    );
  }
}
