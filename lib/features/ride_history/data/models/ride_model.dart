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
    super.polyline,
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
      polyline: json['polyline'] as String?,
      points: rawPoints
          .map((p) {
            final map = p as Map<String, dynamic>;
            // Backend bazen PascalCase ("Lat"/"Lng"/"Ts"/"Spd"),
            // bazen lowercase ("lat"/"lng"/"ts"/"spd") dönebiliyor — ikisini de
            // kabul et ve null/eksik kayıtları sessizce atla.
            final lat = (map['lat'] ?? map['Lat']) as num?;
            final lng = (map['lng'] ?? map['Lng']) as num?;
            final ts = (map['ts'] ?? map['Ts']) as String?;
            if (lat == null || lng == null || ts == null) return null;
            return RidePoint(
              latitude: lat.toDouble(),
              longitude: lng.toDouble(),
              timestamp: DateTime.parse(ts),
              speedKmh: ((map['spd'] ?? map['Spd']) as num?)?.toDouble(),
            );
          })
          .whereType<RidePoint>()
          .toList(),
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
    if (polyline != null) 'polyline': polyline,
    'points': points.map((p) => {
      'lat': p.latitude,
      'lng': p.longitude,
      'ts': p.timestamp.toIso8601String(),
      if (p.speedKmh != null) 'spd': p.speedKmh,
    }).toList(),
  };
}
