import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'route_leg_entity.dart';
import 'route_step_entity.dart';

class RouteEntity {
  final LineString geometry;
  final double distanceMeters;
  final double durationSeconds;
  final List<RouteLegEntity> legs;
  final List<RouteStepEntity> steps;
  final String? summary;
  final double? traffic;
  final List<String>? congestion;

  const RouteEntity({
    required this.geometry,
    required this.distanceMeters,
    required this.durationSeconds,
    this.legs = const [],
    this.steps = const [],
    this.summary,
    this.traffic,
    this.congestion,
  });
}
