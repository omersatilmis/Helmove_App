import '../../domain/entities/voice_session_entity.dart';
import 'voice_session_participant_model.dart';

class VoiceSessionModel extends VoiceSessionEntity {
  const VoiceSessionModel({
    required super.id,
    required super.hostUserId,
    super.hostUsername,
    super.hostFirstName,
    super.hostLastName,
    super.hostProfileImage,
    required super.title,
    required super.roomName,
    required super.isActive,
    required super.createdAt,
    super.rideId,
    super.maxParticipants = 10,
    super.destination,
    super.ridingStyle,
    super.difficulty,
    required List<VoiceSessionParticipantModel> super.participants,
    super.joinedCount = 0,
  });

  factory VoiceSessionModel.fromJson(Map<String, dynamic> json) {
    // Handle nested 'data' wrapper if present
    final data = json.containsKey('data') ? json['data'] : json;

    final host = data['host'] as Map<String, dynamic>?;
    final participantsList =
        (data['participants'] as List<dynamic>?)
            ?.map((p) => VoiceSessionParticipantModel.fromJson(p))
            .toList() ??
        [];

    return VoiceSessionModel(
      id: data['id'] ?? 0,
      hostUserId: data['hostUserId'] ?? 0,
      hostUsername: host?['username'],
      hostFirstName: host?['firstName'],
      hostLastName: host?['lastName'],
      hostProfileImage: host?['profilePictureUrl'],
      title: data['title'] ?? '',
      roomName: data['roomName'] ?? '',
      isActive: data['isActive'] ?? true,
      rideId: data['rideId'],
      maxParticipants: data['maxParticipants'] ?? 10,
      destination: data['destination'],
      ridingStyle: data['ridingStyle'],
      difficulty: data['difficulty'],
      createdAt: data['createdAt'] != null
          ? DateTime.tryParse(data['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      participants: participantsList,
      joinedCount: data['joinedCount'] ?? 0,
    );
  }

  VoiceSessionEntity toEntity() => this;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'hostUserId': hostUserId,
      'title': title,
      'roomName': roomName,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
