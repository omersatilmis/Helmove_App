import '../../domain/entities/voice_session_participant_entity.dart';

class VoiceSessionParticipantModel extends VoiceSessionParticipantEntity {
  const VoiceSessionParticipantModel({
    required super.userId,
    super.username,
    super.firstName,
    super.lastName,
    super.profileImage,
    required super.status,
    super.joinedAt,
  });

  factory VoiceSessionParticipantModel.fromJson(Map<String, dynamic> json) {
    // Backend response structure:
    // { userId, user: { id, username, firstName, lastName, profilePictureUrl }, status, joinedAt }
    final user = json['user'] as Map<String, dynamic>?;

    // Status can be int (enum) or string
    String statusString;
    final rawStatus = json['status'];
    if (rawStatus is int) {
      // Map enum values: 0=Invited, 1=Accepted, 2=Rejected, 3=Joined, 4=Left, 5=Disconnected
      const statusMap = {
        0: 'Invited',
        1: 'Accepted',
        2: 'Rejected',
        3: 'Joined',
        4: 'Left',
        5: 'Disconnected',
      };
      statusString = statusMap[rawStatus] ?? 'Unknown';
    } else {
      statusString = rawStatus?.toString() ?? 'Unknown';
    }

    return VoiceSessionParticipantModel(
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

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'status': status,
      'joinedAt': joinedAt?.toIso8601String(),
    };
  }
}
