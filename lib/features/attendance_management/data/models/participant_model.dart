import '../../domain/entities/participant_entity.dart';
import '../../domain/entities/group_role.dart';

class ParticipantModel extends ParticipantEntity {
  const ParticipantModel({
    required super.userId,
    required super.username,
    super.firstName,
    super.lastName,
    super.profileImageUrl,
    required super.status,
    required super.role,
    super.joinMessage,
    super.requestDate,
  });

  factory ParticipantModel.fromJson(Map<String, dynamic> json) {
    // Backend sends an Integer (0, 1, 2) for Role. Enum values are indices.
    GroupRole parsedRole = GroupRole.rider;
    if (json['role'] != null) {
      if (json['role'] is int) {
        int roleIndex = json['role'];
        if (roleIndex >= 0 && roleIndex < GroupRole.values.length) {
          parsedRole = GroupRole.values[roleIndex];
        }
      } else if (json['role'] is String) {
        parsedRole = GroupRole.fromString(json['role']);
      }
    }

    return ParticipantModel(
      userId: json['userId'] as int? ?? 0,
      username: json['username'] as String? ?? '',
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      // Backend `profilePictureUrl` gönderiyor; eski `profileImageUrl` anahtarı
      // fallback olarak korunur.
      profileImageUrl: (json['profilePictureUrl'] ?? json['profileImageUrl'])
          as String?,
      status: json['status'] as String? ?? '',
      role: parsedRole,
      joinMessage: json['joinMessage'] as String?,
      // Backend `joinedAt` gönderiyor; eski `requestDate` anahtarı fallback.
      requestDate: (json['joinedAt'] ?? json['requestDate']) != null
          ? DateTime.parse(
              (json['joinedAt'] ?? json['requestDate']) as String,
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'username': username,
      'firstName': firstName,
      'lastName': lastName,
      'profileImageUrl': profileImageUrl,
      'status': status,
      'role': role.index,
      'joinMessage': joinMessage,
      'requestDate': requestDate?.toIso8601String(),
    };
  }
}
