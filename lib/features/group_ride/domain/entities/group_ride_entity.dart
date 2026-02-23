/// Grup sürüşü entity'si
/// organizerId = Admin (sürüşü organize eden) kullanıcı ID'si
class GroupRideEntity {
  final int id;
  final String title;
  final String? description;
  final int organizerId; // Admin ID (Backend field adı: organizerId)
  final DateTime startDateTime;
  final DateTime endDateTime;
  final String startLocation;
  final double startLatitude;
  final double startLongitude;
  final String endLocation;
  final double endLatitude;
  final double endLongitude;
  final int maxParticipants;
  final double? estimatedDistanceKm;
  final int? estimatedDurationMinutes;
  final String status;
  final String? difficulty;
  final String? ridingStyle;
  final String? requirements;
  final bool isPrivate;

  GroupRideEntity({
    required this.id,
    required this.title,
    this.description,
    required this.organizerId,
    required this.startDateTime,
    required this.endDateTime,
    required this.startLocation,
    required this.startLatitude,
    required this.startLongitude,
    required this.endLocation,
    required this.endLatitude,
    required this.endLongitude,
    required this.maxParticipants,
    this.estimatedDistanceKm,
    this.estimatedDurationMinutes,
    required this.status,
    this.difficulty,
    this.ridingStyle,
    this.requirements,
    required this.isPrivate,
    this.sessionId,
  });

  final int? sessionId;
}
