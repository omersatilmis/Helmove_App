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
    super.requirements,
  });

  factory GroupRideModel.fromJson(Map<String, dynamic> json) {
    return GroupRideModel(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'],
      organizerId: json['organizerId'] ?? 0,
      startDateTime: DateTime.parse(json['startDateTime']),
      endDateTime: DateTime.parse(json['endDateTime']),
      startLocation: json['startLocation'] ?? '',
      startLatitude: (json['startLatitude'] as num).toDouble(),
      startLongitude: (json['startLongitude'] as num).toDouble(),
      endLocation: json['endLocation'] ?? '',
      endLatitude: (json['endLatitude'] as num).toDouble(),
      endLongitude: (json['endLongitude'] as num).toDouble(),
      maxParticipants: json['maxParticipants'] ?? 0,
      estimatedDistanceKm: (json['estimatedDistanceKm'] as num?)?.toDouble(),
      estimatedDurationMinutes: json['estimatedDurationMinutes'] as int?,
      status: json['status'] ?? '',
      difficulty: json['difficulty'],
      requirements: json['requirements'],
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
      'requirements': requirements,
    };
  }
}
