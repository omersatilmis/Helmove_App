import 'group_ride_participant_entity.dart';

/// GroupRide domain entity
class GroupRideEntity {
  final int id;
  final String title;
  final String description;
  final int organizerId;
  final DateTime startDateTime;
  final DateTime? endDateTime;
  final String startLocation;
  final double startLatitude;
  final double startLongitude;
  final String? endLocation;
  final double? endLatitude;
  final double? endLongitude;
  final int maxParticipants;
  final double? estimatedDistanceKm;
  final int? estimatedDurationMinutes;
  final String status;
  final String difficulty;
  final String? requirements;
  final List<GroupRideParticipantEntity>? participants;

  const GroupRideEntity({
    required this.id,
    required this.title,
    required this.description,
    required this.organizerId,
    required this.startDateTime,
    this.endDateTime,
    required this.startLocation,
    required this.startLatitude,
    required this.startLongitude,
    this.endLocation,
    this.endLatitude,
    this.endLongitude,
    required this.maxParticipants,
    this.estimatedDistanceKm,
    this.estimatedDurationMinutes,
    required this.status,
    required this.difficulty,
    this.requirements,
    this.participants,
  });

  /// Katılımcı sayısını döndürür
  int get currentParticipants => participants?.length ?? 0;

  /// Aktif mi kontrolü
  bool get isActive => status == 'Active' || status == 'InProgress';

  /// Planlamada mı kontrolü
  bool get isPlanning => status == 'Planning';
}
