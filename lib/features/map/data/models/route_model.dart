import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import '../../domain/entities/route_entity.dart';
import '../../domain/entities/route_leg_entity.dart';
import '../../domain/entities/route_step_entity.dart';

class RouteModel extends RouteEntity {
  const RouteModel({
    required super.geometry,
    required super.distanceMeters,
    required super.durationSeconds,
    super.legs,
    super.steps,
    super.summary,
    super.traffic,
    super.congestion,
  });

  factory RouteModel.fromJson(Map<String, dynamic> json) {
    final geometry = json['geometry'] as Map<String, dynamic>;
    final coordsList = geometry['coordinates'] as List<dynamic>;
    
    final points = <Point>[];
    for (final item in coordsList) {
      final lng = (item[0] as num).toDouble();
      final lat = (item[1] as num).toDouble();
      points.add(Point(coordinates: Position(lng, lat)));
    }

    final legs = _parseLegs(json['legs']);
    final steps = _flattenSteps(legs);
    final summary = _parseSummary(json, legs);
    final traffic = _parseTraffic(json);
    final congestion = _parseRouteCongestion(legs);

    return RouteModel(
      geometry: LineString.fromPoints(points: points),
      distanceMeters: (json['distance'] as num).toDouble(),
      durationSeconds: (json['duration'] as num).toDouble(),
      legs: legs,
      steps: steps,
      summary: summary,
      traffic: traffic,
      congestion: congestion,
    );
  }

  static List<RouteLegEntity> _parseLegs(dynamic value) {
    if (value is! List) return const [];
    final legs = <RouteLegEntity>[];
    for (final item in value) {
      if (item is! Map<String, dynamic>) continue;
      final distance = _asDouble(item['distance']) ?? 0;
      final duration = _asDouble(item['duration']) ?? 0;
      final summary = item['summary'] as String?;
      final steps = _parseSteps(item['steps']);
      final congestion = _parseCongestion(item['annotation']);
      legs.add(RouteLegEntity(
        distanceMeters: distance,
        durationSeconds: duration,
        summary: summary,
        steps: steps,
        congestion: congestion,
      ));
    }
    return legs;
  }

  static List<RouteStepEntity> _parseSteps(dynamic value) {
    if (value is! List) return const [];
    final steps = <RouteStepEntity>[];
    for (final item in value) {
      if (item is! Map<String, dynamic>) continue;
      final distance = _asDouble(item['distance']) ?? 0;
      final duration = _asDouble(item['duration']) ?? 0;
      final name = item['name'] as String?;
      final maneuver = item['maneuver'] as Map<String, dynamic>?;
      final instruction = maneuver?['instruction'] as String?;
      final maneuverType = maneuver?['type'] as String?;
      final maneuverModifier = maneuver?['modifier'] as String?;
      final maneuverLocation = _parsePoint(maneuver?['location']);
      final geometry = _parseLineString(item['geometry']);
      steps.add(RouteStepEntity(
        distanceMeters: distance,
        durationSeconds: duration,
        name: name,
        instruction: instruction,
        maneuverType: maneuverType,
        maneuverModifier: maneuverModifier,
        maneuverLocation: maneuverLocation,
        geometry: geometry,
      ));
    }
    return steps;
  }

  static List<RouteStepEntity> _flattenSteps(List<RouteLegEntity> legs) {
    if (legs.isEmpty) return const [];
    final steps = <RouteStepEntity>[];
    for (final leg in legs) {
      steps.addAll(leg.steps);
    }
    return steps;
  }

  static String? _parseSummary(
    Map<String, dynamic> json,
    List<RouteLegEntity> legs,
  ) {
    final direct = json['summary'];
    if (direct is String && direct.trim().isNotEmpty) {
      return direct.trim();
    }
    for (final leg in legs) {
      final summary = leg.summary;
      if (summary != null && summary.trim().isNotEmpty) {
        return summary.trim();
      }
    }
    return null;
  }

  static double? _parseTraffic(Map<String, dynamic> json) {
    final typical = json['duration_typical'];
    if (typical is num) return typical.toDouble();
    final traffic = json['traffic'];
    if (traffic is num) return traffic.toDouble();
    return null;
  }

  static List<String>? _parseRouteCongestion(List<RouteLegEntity> legs) {
    if (legs.isEmpty) return null;
    final merged = <String>[];
    for (final leg in legs) {
      final congestion = leg.congestion;
      if (congestion != null && congestion.isNotEmpty) {
        merged.addAll(congestion);
      }
    }
    return merged.isEmpty ? null : merged;
  }

  static double? _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return null;
  }

  static Point? _parsePoint(dynamic value) {
    if (value is List && value.length >= 2) {
      final lng = _asDouble(value[0]);
      final lat = _asDouble(value[1]);
      if (lng != null && lat != null) {
        return Point(coordinates: Position(lng, lat));
      }
    }
    return null;
  }

  static LineString? _parseLineString(dynamic geometry) {
    if (geometry is! Map<String, dynamic>) return null;
    final coords = geometry['coordinates'];
    if (coords is! List) return null;
    final points = <Point>[];
    for (final item in coords) {
      if (item is List && item.length >= 2) {
        final lng = _asDouble(item[0]);
        final lat = _asDouble(item[1]);
        if (lng != null && lat != null) {
          points.add(Point(coordinates: Position(lng, lat)));
        }
      }
    }
    if (points.isEmpty) return null;
    return LineString.fromPoints(points: points);
  }

  static List<String>? _parseCongestion(dynamic annotation) {
    if (annotation is! Map<String, dynamic>) return null;
    final congestion = annotation['congestion'];
    if (congestion is! List) return null;
    final values = <String>[];
    for (final item in congestion) {
      if (item is String && item.trim().isNotEmpty) {
        values.add(item.trim());
      }
    }
    return values.isEmpty ? null : values;
  }
}
