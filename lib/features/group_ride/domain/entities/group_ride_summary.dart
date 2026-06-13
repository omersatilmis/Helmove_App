/// Grup sürüşü liste/keşfet özeti.
///
/// search / nearby / by-status / my-* gibi liste endpoint'lerinin döndürdüğü
/// zengin kart verisi için hafif model. Tam [GroupRideEntity]'den ayrıdır;
/// detay alanlarını (rota, koordinatlar vb.) içermez, ama kart için gereken
/// kapak/organizatör/doluluk/mesafe alanlarını içerir.
class GroupRideSummary {
  final int id;
  final String title;
  final String startLocation;
  final DateTime startDateTime;
  final double? estimatedDistanceKm;
  final int? estimatedDurationMinutes;

  /// Planning | Active | InProgress | Completed | Cancelled | Postponed
  final String status;

  /// Beginner | Intermediate | Advanced | Expert
  final String difficulty;

  /// Sakin | Tour | Viraj | Sehir
  final String ridingStyle;

  final String? coverImageUrl;
  final int organizerId;
  final String? organizerName;
  final String? organizerAvatarUrl;
  final int maxParticipants;
  final int currentParticipantCount;

  /// Sadece /nearby sonuçlarında dolu (Haversine, 1 ondalık). search'te null.
  final double? distanceKm;

  final bool isPrivate;

  const GroupRideSummary({
    required this.id,
    required this.title,
    required this.startLocation,
    required this.startDateTime,
    this.estimatedDistanceKm,
    this.estimatedDurationMinutes,
    required this.status,
    required this.difficulty,
    required this.ridingStyle,
    this.coverImageUrl,
    required this.organizerId,
    this.organizerName,
    this.organizerAvatarUrl,
    required this.maxParticipants,
    required this.currentParticipantCount,
    this.distanceKm,
    required this.isPrivate,
  });

  /// Doluluk etiketi: "8/15".
  String get occupancyLabel => '$currentParticipantCount/$maxParticipants';

  /// Kapasite dolu mu?
  bool get isFull =>
      maxParticipants > 0 && currentParticipantCount >= maxParticipants;
}
