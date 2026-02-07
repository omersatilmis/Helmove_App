import '../../domain/entities/participant_entity.dart';

class ParticipantModel extends ParticipantEntity {
  const ParticipantModel({
    required super.userId,
    required super.username,
    super.firstName,
    super.lastName,
    super.profileImageUrl,
    required super.status,
    super.requestDate,
  });

  factory ParticipantModel.fromJson(Map<String, dynamic> json) {
    return ParticipantModel(
      userId: json['userId'] as int? ?? 0,
      username: json['username'] as String? ?? '',
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      profileImageUrl: json['profileImageUrl'] as String?,
      status: json['status'] as String? ?? '',
      requestDate: json['requestDate'] != null
          ? DateTime.parse(json['requestDate'] as String)
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
      'requestDate': requestDate?.toIso8601String(),
    };
  }
}
