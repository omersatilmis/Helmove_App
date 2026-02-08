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
    };
  }
}
