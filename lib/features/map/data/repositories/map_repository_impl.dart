import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import '../../domain/entities/location_entity.dart';
import '../../domain/entities/route_entity.dart';
import '../../domain/repositories/map_repository.dart';
import '../datasources/map_remote_data_source.dart';

class MapRepositoryImpl implements MapRepository {
  final MapRemoteDataSource remoteDataSource;

  MapRepositoryImpl({required this.remoteDataSource});

  @override
  Future<LocationEntity?> forwardGeocode(String query, {Point? proximity}) =>
      remoteDataSource.forwardGeocode(query, proximity: proximity);

  @override
  Future<List<LocationEntity>> searchLocations(
    String query, {
    Point? proximity,
    CoordinateBounds? bbox,
    List<String>? types,
    int limit = 6,
  }) =>
      remoteDataSource.searchLocations(
        query,
        proximity: proximity,
        bbox: bbox,
        types: types,
        limit: limit,
      );

  @override
  Future<LocationEntity?> reverseGeocode(Point point, {List<String>? types}) =>
      remoteDataSource.reverseGeocode(point, types: types);

  @override
  Future<List<RouteEntity>> getRoutes(List<Point> waypoints) =>
      remoteDataSource.getRoutes(waypoints);
}
