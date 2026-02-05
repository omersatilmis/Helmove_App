import '../../domain/entities/group_ride_participant_entity.dart';

/// GroupRide Participant için model sınıfı
class GroupRideParticipantModel {
  final int id;
  final int userId;
  final String username;
  final String firstName;
  final String lastName;
  final String status;
  final DateTime joinedAt;
  final String? joinMessage;
  final String? profilePictureUrl;

  GroupRideParticipantModel({
    required this.id,
    required this.userId,
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.status,
    required this.joinedAt,
    this.joinMessage,
    this.profilePictureUrl,
  });

  factory GroupRideParticipantModel.fromJson(Map<String, dynamic> json) {
    return GroupRideParticipantModel(
      id: json['id'] as int,
      userId: json['userId'] as int,
      username: json['username'] as String? ?? '',
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      status: json['status'] as String? ?? '',
      joinedAt: DateTime.parse(json['joinedAt'] as String),
      joinMessage: json['joinMessage'] as String?,
      profilePictureUrl: json['profilePictureUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'username': username,
      'firstName': firstName,
      'lastName': lastName,
      'status': status,
      'joinedAt': joinedAt.toIso8601String(),
      'joinMessage': joinMessage,
      'profilePictureUrl': profilePictureUrl,
    };
  }

  /// Model'i Entity'e dönüştürür
  GroupRideParticipantEntity toEntity() {
    return GroupRideParticipantEntity(
      id: id,
      userId: userId,
      username: username,
      firstName: firstName,
      lastName: lastName,
      status: status,
      joinedAt: joinedAt,
      joinMessage: joinMessage,
      profilePictureUrl: profilePictureUrl,
    );
  }
}
