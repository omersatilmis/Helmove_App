class RideEntity {
  final int? id;
  final String title;
  final DateTime startedAt;
  final DateTime? endedAt;
  final double distanceKm;
  final int durationSeconds;
  final double? avgSpeedKmh;
  final double? maxSpeedKmh;
  final String? startCity;
  final String? endCity;
  final List<RidePoint> points;

  const RideEntity({
    this.id,
    required this.title,
    required this.startedAt,
    this.endedAt,
    required this.distanceKm,
    required this.durationSeconds,
    this.avgSpeedKmh,
    this.maxSpeedKmh,
    this.startCity,
    this.endCity,
    this.points = const [],
  });

  Duration get duration => Duration(seconds: durationSeconds);

  String get durationFormatted {
    final h = duration.inHours;
    final m = duration.inMinutes.remainder(60);
    if (h > 0) return '${h}s ${m}dk';
    return '${m}dk';
  }

  String get distanceFormatted =>
      distanceKm >= 10 ? '${distanceKm.toStringAsFixed(0)} km' : '${distanceKm.toStringAsFixed(1)} km';

  String get routeLabel {
    if (startCity != null && endCity != null && startCity != endCity) {
      return '$startCity → $endCity';
    }
    return startCity ?? endCity ?? '';
  }
}

class RidePoint {
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final double? speedKmh;

  const RidePoint({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.speedKmh,
  });
}
