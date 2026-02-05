import '../../domain/entities/voice_session_participant_entity.dart';

/// Backend'den gelen SessionParticipantDto'yu parse eden DTO
class VoiceSessionParticipantDto {
  final int userId;
  final String? username;
  final String? firstName;
  final String? lastName;
  final String? profileImage;
  final String status;
  final DateTime? joinedAt;

  VoiceSessionParticipantDto({
    required this.userId,
    this.username,
    this.firstName,
    this.lastName,
    this.profileImage,
    required this.status,
    this.joinedAt,
  });

  factory VoiceSessionParticipantDto.fromJson(Map<String, dynamic> json) {
    // Backend response structure:
    // { userId, user: { id, username, firstName, lastName, profilePictureUrl }, status, joinedAt }

    final user = json['user'] as Map<String, dynamic>?;

    // Status can be int (enum) or string
    String statusString;
    final rawStatus = json['status'];
    if (rawStatus is int) {
      // Map enum values: 0=Invited, 1=Accepted, 2=Rejected, 3=Joined, 4=Left
      const statusMap = {
        0: 'Invited',
        1: 'Accepted',
        2: 'Rejected',
        3: 'Joined',
        4: 'Left',
      };
      statusString = statusMap[rawStatus] ?? 'Unknown';
    } else {
      statusString = rawStatus?.toString() ?? 'Unknown';
    }

    return VoiceSessionParticipantDto(
      userId: json['userId'] ?? user?['id'] ?? 0,
      username: user?['username'],
      firstName: user?['firstName'],
      lastName: user?['lastName'],
      profileImage: user?['profilePictureUrl'],
      status: statusString,
      joinedAt: json['joinedAt'] != null
          ? DateTime.tryParse(json['joinedAt'])
          : null,
    );
  }

  VoiceSessionParticipantEntity toEntity() {
    return VoiceSessionParticipantEntity(
      userId: userId,
      username: username,
      firstName: firstName,
      lastName: lastName,
      profileImage: profileImage,
      status: status,
      joinedAt: joinedAt,
    );
  }
}
