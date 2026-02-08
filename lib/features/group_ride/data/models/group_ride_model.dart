import '../../domain/entities/group_ride_entity.dart';

class GroupRideModel extends GroupRideEntity {
  GroupRideModel({
    required super.id,
    required super.title,
    super.description,
    required super.organizerId,
    required super.startDateTime,
    required super.endDateTime,
    required super.startLocation,
    required super.startLatitude,
    required super.startLongitude,
    required super.endLocation,
    required super.endLatitude,
    required super.endLongitude,
    required super.maxParticipants,
    super.estimatedDistanceKm,
    super.estimatedDurationMinutes,
    required super.status,
    super.difficulty,
    super.ridingStyle,
    super.requirements,
    required super.isPrivate,
    super.voiceSessionId,
  });

  factory GroupRideModel.fromJson(Map<String, dynamic> json) {
    return GroupRideModel(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      organizerId: json['organizerId'] as int? ?? 0,
      startDateTime: json['startDateTime'] != null
          ? DateTime.parse(json['startDateTime'] as String)
          : DateTime.now(),
      endDateTime: json['endDateTime'] != null
          ? DateTime.parse(json['endDateTime'] as String)
          : DateTime.now(),
      startLocation: json['startLocation'] as String? ?? '',
      startLatitude: (json['startLatitude'] as num?)?.toDouble() ?? 0.0,
      startLongitude: (json['startLongitude'] as num?)?.toDouble() ?? 0.0,
      endLocation: json['endLocation'] as String? ?? '',
      endLatitude: (json['endLatitude'] as num?)?.toDouble() ?? 0.0,
      endLongitude: (json['endLongitude'] as num?)?.toDouble() ?? 0.0,
      maxParticipants: json['maxParticipants'] as int? ?? 0,
      estimatedDistanceKm: (json['estimatedDistanceKm'] as num?)?.toDouble(),
      estimatedDurationMinutes: json['estimatedDurationMinutes'] as int?,
      status: json['status'] as String? ?? '',
      difficulty: json['difficulty'] as String?,
      ridingStyle: json['ridingStyle'] as String?,
      requirements: json['requirements'] as String?,
      isPrivate: json['isPrivate'] as bool? ?? false,
      voiceSessionId: json['voiceSessionId'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'organizerId': organizerId,
      'startDateTime': startDateTime.toIso8601String(),
      'endDateTime': endDateTime.toIso8601String(),
      'startLocation': startLocation,
      'startLatitude': startLatitude,
      'startLongitude': startLongitude,
      'endLocation': endLocation,
      'endLatitude': endLatitude,
      'endLongitude': endLongitude,
      'maxParticipants': maxParticipants,
      'estimatedDistanceKm': estimatedDistanceKm,
      'estimatedDurationMinutes': estimatedDurationMinutes,
      'status': status,
      'difficulty': difficulty,
      'ridingStyle': ridingStyle,
      'isPrivate': isPrivate,
      'requirements': requirements,
      'voiceSessionId': voiceSessionId,
    };
  }
}
