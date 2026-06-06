import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'route_leg_entity.dart';
import 'route_step_entity.dart';

/// Rota seçenek kategorisi: en hızlı (paralı yol kullanabilir) veya ücretsiz.
enum RouteCategory { fastest, free }

class RouteEntity {
  final LineString geometry;
  final double distanceMeters;
  final double durationSeconds;
  final List<RouteLegEntity> legs;
  final List<RouteStepEntity> steps;
  final String? summary;
  final double? traffic;
  final List<String>? congestion;
  final RouteCategory category;
  final bool hasToll;

  const RouteEntity({
    required this.geometry,
    required this.distanceMeters,
    required this.durationSeconds,
    this.legs = const [],
    this.steps = const [],
    this.summary,
    this.traffic,
    this.congestion,
    this.category = RouteCategory.fastest,
    this.hasToll = false,
  });

  RouteEntity copyWith({
    RouteCategory? category,
    bool? hasToll,
  }) {
    return RouteEntity(
      geometry: geometry,
      distanceMeters: distanceMeters,
      durationSeconds: durationSeconds,
      legs: legs,
      steps: steps,
      summary: summary,
      traffic: traffic,
      congestion: congestion,
      category: category ?? this.category,
      hasToll: hasToll ?? this.hasToll,
    );
  }
}
