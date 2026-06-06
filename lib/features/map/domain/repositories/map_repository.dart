import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import '../entities/location_entity.dart';
import '../entities/route_entity.dart';

abstract class MapRepository {
  Future<LocationEntity?> forwardGeocode(String query, {Point? proximity});
  Future<List<LocationEntity>> searchLocations(
    String query, {
    Point? proximity,
    CoordinateBounds? bbox,
    List<String>? types,
    int limit = 6,
  });
  Future<LocationEntity?> reverseGeocode(Point point, {List<String>? types});
  Future<List<RouteEntity>> getRoutes(
    List<Point> waypoints, {
    bool excludeToll = false,
  });
}
