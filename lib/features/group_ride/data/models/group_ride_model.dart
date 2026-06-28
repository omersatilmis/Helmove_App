import '../../domain/entities/group_ride_entity.dart';

class GroupRideModel extends GroupRideEntity {
  GroupRideModel({
    required super.id,
    required super.title,
    super.description,
    required super.adminId,
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
    super.sessionId,
    super.routeGeometry,
    super.routeProfile,
    super.routeDistanceMeters,
    super.routeDurationSeconds,
    super.routeImageUrl,
    super.organizerName,
    super.organizerAvatarUrl,
    super.coverImageUrl,
  });

  factory GroupRideModel.fromJson(Map<String, dynamic> json) {
    return GroupRideModel(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      adminId: json['organizerId'] as int? ?? 0, // GÜVENLİK: API Key korunuyor
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
      sessionId: json['sessionId'] as int?,
      routeGeometry: json['routeGeometry'] as String?,
      routeProfile: json['routeProfile'] as String?,
      routeDistanceMeters: (json['routeDistanceMeters'] as num?)?.toDouble(),
      routeDurationSeconds: json['routeDurationSeconds'] as int?,
      routeImageUrl: json['routeImageUrl'] as String?,
      organizerName: json['organizerName'] as String?,
      organizerAvatarUrl: json['organizerAvatarUrl'] as String?,
      coverImageUrl: json['coverImageUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'organizerId': adminId, // GÜVENLİK: API Key korunuyor
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
      'sessionId': sessionId,
      'routeGeometry': routeGeometry,
      'routeProfile': routeProfile,
      'routeDistanceMeters': routeDistanceMeters,
      'routeDurationSeconds': routeDurationSeconds,
    };
  }
}
