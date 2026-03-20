import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

class RouteStepEntity {
  final double distanceMeters;
  final double durationSeconds;
  final String? name;
  final String? instruction;
  final String? maneuverType;
  final String? maneuverModifier;
  final Point? maneuverLocation;
  final LineString? geometry;

  const RouteStepEntity({
    required this.distanceMeters,
    required this.durationSeconds,
    this.name,
    this.instruction,
    this.maneuverType,
    this.maneuverModifier,
    this.maneuverLocation,
    this.geometry,
  });
}
