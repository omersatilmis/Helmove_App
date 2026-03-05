import '../../domain/entities/voice_session_entity.dart';
import 'voice_session_participant_model.dart';

class VoiceSessionModel extends VoiceSessionEntity {
  const VoiceSessionModel({
    required super.id,
    required super.adminId,
    super.adminUsername,
    super.adminFirstName,
    super.adminLastName,
    super.adminProfileImage,
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
    int? parseNullableInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      return int.tryParse(value.toString());
    }

    // Handle nested 'data' wrapper if present
    final data = json.containsKey('data') ? json['data'] : json;

    final host = data['host'] as Map<String, dynamic>?;
    final participantsList =
        (data['participants'] as List<dynamic>?)
            ?.map((p) => VoiceSessionParticipantModel.fromJson(p))
            .toList() ??
        [];

    return VoiceSessionModel(
      id: parseNullableInt(data['id']) ?? 0,
      adminId: data['adminId'] != null
          ? parseNullableInt(data['adminId']) ??
                parseNullableInt(data['hostUserId']) ??
                0
          : parseNullableInt(data['hostUserId']) ?? 0,
      adminUsername: host?['username'],
      adminFirstName: host?['firstName'],
      adminLastName: host?['lastName'],
      adminProfileImage: host?['profilePictureUrl'],
      title: data['title'] ?? '',
      roomName: data['roomName'] ?? '',
      isActive: data['isActive'] ?? true,
      rideId: parseNullableInt(data['rideId'] ?? data['groupRideId']),
      maxParticipants: parseNullableInt(data['maxParticipants']) ?? 10,
      destination: data['destination'],
      ridingStyle: data['ridingStyle'],
      difficulty: data['difficulty'],
      createdAt: data['createdAt'] != null
          ? DateTime.tryParse(data['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      participants: participantsList,
      joinedCount: parseNullableInt(data['joinedCount']) ?? 0,
    );
  }

  VoiceSessionEntity toEntity() => this;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'hostUserId': adminId, // GÜVENLİK: API Key korunuyor
      'title': title,
      'roomName': roomName,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
