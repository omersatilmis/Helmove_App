class CreateGroupRideRequestDto {
  final String title;
  final String? description;
  final DateTime startDateTime;
  final DateTime endDateTime;
  final String startLocation;
  final double startLatitude;
  final double startLongitude;
  final String endLocation;
  final double endLatitude;
  final double endLongitude;
  final int maxParticipants;
  final String? difficulty;
  final String? ridingStyle;
  final String privacy;
  final List<int>? invitedUserIds;

  // Ortak rota (organizatörün planlayıcıda seçtiği rota — seçilen alternatif +
  // duraklar gömülü). routeGeometry encoded polyline6 (PolylineCodec).
  final String? routeGeometry;
  final String? routeProfile;
  final double? routeDistanceMeters;
  final int? routeDurationSeconds;

  CreateGroupRideRequestDto({
    required this.title,
    this.description,
    required this.startDateTime,
    required this.endDateTime,
    required this.startLocation,
    required this.startLatitude,
    required this.startLongitude,
    required this.endLocation,
    required this.endLatitude,
    required this.endLongitude,
    required this.maxParticipants,
    this.difficulty,
    this.ridingStyle,
    required this.privacy,
    this.invitedUserIds,
    this.routeGeometry,
    this.routeProfile,
    this.routeDistanceMeters,
    this.routeDurationSeconds,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'startDateTime': startDateTime.toIso8601String(),
      'endDateTime': endDateTime.toIso8601String(),
      'startLocation': startLocation,
      'startLatitude': startLatitude,
      'startLongitude': startLongitude,
      'endLocation': endLocation,
      'endLatitude': endLatitude,
      'endLongitude': endLongitude,
      'maxParticipants': maxParticipants,
      'difficulty': difficulty,
      'ridingStyle': ridingStyle,
      'privacy': privacy,
      'invitedUserIds': invitedUserIds ?? [],
      if (routeGeometry != null) 'routeGeometry': routeGeometry,
      if (routeProfile != null) 'routeProfile': routeProfile,
      if (routeDistanceMeters != null) 'routeDistanceMeters': routeDistanceMeters,
      if (routeDurationSeconds != null) 'routeDurationSeconds': routeDurationSeconds,
    };
  }
}
