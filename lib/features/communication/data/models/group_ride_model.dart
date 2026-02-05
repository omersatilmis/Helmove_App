import '../../domain/entities/group_ride_entity.dart';
import 'group_ride_participant_model.dart';

/// GroupRide için model sınıfı
class GroupRideModel {
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
  final List<GroupRideParticipantModel>? participants;

  GroupRideModel({
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

  factory GroupRideModel.fromJson(Map<String, dynamic> json) {
    return GroupRideModel(
      id: json['id'] as int,
      title: json['title'] as String,
      description: json['description'] as String,
      organizerId: json['organizerId'] as int,
      startDateTime: DateTime.parse(json['startDateTime'] as String),
      endDateTime: json['endDateTime'] != null
          ? DateTime.parse(json['endDateTime'] as String)
          : null,
      startLocation: json['startLocation'] as String,
      startLatitude: (json['startLatitude'] as num).toDouble(),
      startLongitude: (json['startLongitude'] as num).toDouble(),
      endLocation: json['endLocation'] as String?,
      endLatitude: json['endLatitude'] != null
          ? (json['endLatitude'] as num).toDouble()
          : null,
      endLongitude: json['endLongitude'] != null
          ? (json['endLongitude'] as num).toDouble()
          : null,
      maxParticipants: json['maxParticipants'] as int? ?? 10,
      estimatedDistanceKm: json['estimatedDistanceKm'] != null
          ? (json['estimatedDistanceKm'] as num).toDouble()
          : null,
      estimatedDurationMinutes: json['estimatedDurationMinutes'] as int?,
      status: json['status'] as String? ?? 'Planning',
      difficulty: json['difficulty'] as String? ?? 'Beginner',
      requirements: json['requirements'] as String?,
      participants: json['participants'] != null
          ? (json['participants'] as List)
                .map((p) => GroupRideParticipantModel.fromJson(p))
                .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'organizerId': organizerId,
      'startDateTime': startDateTime.toIso8601String(),
      'endDateTime': endDateTime?.toIso8601String(),
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

  /// Model'i Entity'e dönüştürür
  GroupRideEntity toEntity() {
    return GroupRideEntity(
      id: id,
      title: title,
      description: description,
      organizerId: organizerId,
      startDateTime: startDateTime,
      endDateTime: endDateTime,
      startLocation: startLocation,
      startLatitude: startLatitude,
      startLongitude: startLongitude,
      endLocation: endLocation,
      endLatitude: endLatitude,
      endLongitude: endLongitude,
      maxParticipants: maxParticipants,
      estimatedDistanceKm: estimatedDistanceKm,
      estimatedDurationMinutes: estimatedDurationMinutes,
      status: status,
      difficulty: difficulty,
      requirements: requirements,
      participants: participants?.map((p) => p.toEntity()).toList(),
    );
  }
}
