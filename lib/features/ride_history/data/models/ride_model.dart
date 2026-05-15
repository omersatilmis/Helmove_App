import '../../domain/entities/ride_entity.dart';

class RideModel extends RideEntity {
  const RideModel({
    super.id,
    required super.title,
    required super.startedAt,
    super.endedAt,
    required super.distanceKm,
    required super.durationSeconds,
    super.avgSpeedKmh,
    super.maxSpeedKmh,
    super.startCity,
    super.endCity,
    super.points,
  });

  factory RideModel.fromJson(Map<String, dynamic> json) {
    final rawPoints = json['points'] as List<dynamic>? ?? [];
    return RideModel(
      id: json['id'] as int?,
      title: json['title'] as String? ?? 'Sürüş',
      startedAt: DateTime.parse(json['startedAt'] as String),
      endedAt: json['endedAt'] != null
          ? DateTime.parse(json['endedAt'] as String)
          : null,
      distanceKm: (json['distanceKm'] as num?)?.toDouble() ?? 0,
      durationSeconds: json['durationSeconds'] as int? ?? 0,
      avgSpeedKmh: (json['avgSpeedKmh'] as num?)?.toDouble(),
      maxSpeedKmh: (json['maxSpeedKmh'] as num?)?.toDouble(),
      startCity: json['startCity'] as String?,
      endCity: json['endCity'] as String?,
      points: rawPoints.map((p) {
        final map = p as Map<String, dynamic>;
        return RidePoint(
          latitude: (map['lat'] as num).toDouble(),
          longitude: (map['lng'] as num).toDouble(),
          timestamp: DateTime.parse(map['ts'] as String),
          speedKmh: (map['spd'] as num?)?.toDouble(),
        );
      }).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'title': title,
    'startedAt': startedAt.toIso8601String(),
    if (endedAt != null) 'endedAt': endedAt!.toIso8601String(),
    'distanceKm': distanceKm,
    'durationSeconds': durationSeconds,
    if (avgSpeedKmh != null) 'avgSpeedKmh': avgSpeedKmh,
    if (maxSpeedKmh != null) 'maxSpeedKmh': maxSpeedKmh,
    if (startCity != null) 'startCity': startCity,
    if (endCity != null) 'endCity': endCity,
    'points': points.map((p) => {
      'lat': p.latitude,
      'lng': p.longitude,
      'ts': p.timestamp.toIso8601String(),
      if (p.speedKmh != null) 'spd': p.speedKmh,
    }).toList(),
  };
}
