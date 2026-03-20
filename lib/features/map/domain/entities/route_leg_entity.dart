import 'route_step_entity.dart';

class RouteLegEntity {
  final double distanceMeters;
  final double durationSeconds;
  final String? summary;
  final List<RouteStepEntity> steps;
  final List<String>? congestion;

  const RouteLegEntity({
    required this.distanceMeters,
    required this.durationSeconds,
    this.summary,
    this.steps = const [],
    this.congestion,
  });
}
