/// [Rota Planlayıcı] çıkış sonucu.
///
/// Planlayıcı (MapPage planlama modu) "Bu rotayı kullan" denince bunu döndürür.
/// Duraklar ([stops]) Faz 1'de yapısal taşınsa da backend'e gönderilmez;
/// [routeGeometry] zaten seçilen alternatif + duraklardan geçen çizgiyi içerir.
class RoutePlanStop {
  final double lat;
  final double lng;
  final String? label;

  const RoutePlanStop({required this.lat, required this.lng, this.label});
}

class RoutePlanResult {
  final double startLat;
  final double startLng;
  final String startLabel;

  final double endLat;
  final double endLng;
  final String endLabel;

  final List<RoutePlanStop> stops;

  /// Seçilen alternatif + duraklardan geçen encoded polyline (polyline6).
  final String routeGeometry;
  final double distanceMeters;
  final int durationSeconds;
  final String profile;

  const RoutePlanResult({
    required this.startLat,
    required this.startLng,
    required this.startLabel,
    required this.endLat,
    required this.endLng,
    required this.endLabel,
    this.stops = const [],
    required this.routeGeometry,
    required this.distanceMeters,
    required this.durationSeconds,
    this.profile = 'driving',
  });

  double get distanceKm => distanceMeters / 1000.0;
  int get durationMinutes => (durationSeconds / 60).round();
}
