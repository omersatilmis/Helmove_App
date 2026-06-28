/// Grup sürüşü entity'si
/// adminId = Admin (sürüşü organize eden) kullanıcı ID'si
class GroupRideEntity {
  final int id;
  final String title;
  final String? description;
  final int adminId; // Admin ID (Backend field adı: organizerId)
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

  // ── Ortak rota (organizatörün rotası tüm üyelere yayılır) ─────────────────
  /// Encoded polyline (polyline6). Bkz. core/utils/polyline_codec.dart.
  final String? routeGeometry;
  final String? routeProfile;
  final double? routeDistanceMeters;
  final int? routeDurationSeconds;

  /// Backend'in Mapbox Static Images ile ürettiği rota görüntüsü URL'i
  /// (keşfet kartı + detay kapağı için). routeGeometry yoksa null.
  final String? routeImageUrl;

  // ── Organizatör + kapak (detayın summary'den bağımsız çalışması için) ──────
  /// Organizatör görünen adı (backend GET /{id} detayında döner).
  final String? organizerName;
  final String? organizerAvatarUrl;

  /// routeImageUrl yoksa kullanılacak jenerik kapak (backend döndürürse).
  final String? coverImageUrl;

  final int? sessionId;

  GroupRideEntity({
    required this.id,
    required this.title,
    this.description,
    required this.adminId,
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
    this.routeGeometry,
    this.routeProfile,
    this.routeDistanceMeters,
    this.routeDurationSeconds,
    this.routeImageUrl,
    this.organizerName,
    this.organizerAvatarUrl,
    this.coverImageUrl,
  });

  GroupRideEntity copyWith({
    String? routeGeometry,
    String? routeProfile,
    double? routeDistanceMeters,
    int? routeDurationSeconds,
  }) {
    return GroupRideEntity(
      id: id,
      title: title,
      description: description,
      adminId: adminId,
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
      ridingStyle: ridingStyle,
      requirements: requirements,
      isPrivate: isPrivate,
      sessionId: sessionId,
      routeGeometry: routeGeometry ?? this.routeGeometry,
      routeProfile: routeProfile ?? this.routeProfile,
      routeDistanceMeters: routeDistanceMeters ?? this.routeDistanceMeters,
      routeDurationSeconds: routeDurationSeconds ?? this.routeDurationSeconds,
      routeImageUrl: routeImageUrl,
      organizerName: organizerName,
      organizerAvatarUrl: organizerAvatarUrl,
      coverImageUrl: coverImageUrl,
    );
  }
}
