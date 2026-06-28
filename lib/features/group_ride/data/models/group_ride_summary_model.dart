import '../../domain/entities/group_ride_summary.dart';

/// [GroupRideSummary]'nin JSON parse eden data modeli.
///
/// Backend `data[]` item'ı için. Opsiyonel/eksik alanlarda eski cache veya
/// edge response'larda patlamamak için null-guard'lar konuldu.
class GroupRideSummaryModel extends GroupRideSummary {
  const GroupRideSummaryModel({
    required super.id,
    required super.title,
    required super.startLocation,
    required super.startDateTime,
    super.estimatedDistanceKm,
    super.estimatedDurationMinutes,
    required super.status,
    required super.difficulty,
    required super.ridingStyle,
    super.coverImageUrl,
    super.routeImageUrl,
    required super.organizerId,
    super.organizerName,
    super.organizerAvatarUrl,
    required super.maxParticipants,
    required super.currentParticipantCount,
    super.distanceKm,
    required super.isPrivate,
  });

  factory GroupRideSummaryModel.fromJson(Map<String, dynamic> json) {
    return GroupRideSummaryModel(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      startLocation: json['startLocation'] as String? ?? '',
      startDateTime: json['startDateTime'] != null
          ? DateTime.parse(json['startDateTime'] as String)
          : DateTime.now(),
      estimatedDistanceKm: (json['estimatedDistanceKm'] as num?)?.toDouble(),
      estimatedDurationMinutes: json['estimatedDurationMinutes'] as int?,
      status: json['status'] as String? ?? '',
      difficulty: json['difficulty'] as String? ?? '',
      ridingStyle: json['ridingStyle'] as String? ?? '',
      coverImageUrl: json['coverImageUrl'] as String?,
      routeImageUrl: json['routeImageUrl'] as String?,
      organizerId: json['organizerId'] as int? ?? 0,
      organizerName: json['organizerName'] as String?,
      organizerAvatarUrl: json['organizerAvatarUrl'] as String?,
      maxParticipants: json['maxParticipants'] as int? ?? 0,
      currentParticipantCount: json['currentParticipantCount'] as int? ?? 0,
      distanceKm: (json['distanceKm'] as num?)?.toDouble(),
      isPrivate: json['isPrivate'] as bool? ?? false,
    );
  }
}
