import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import '../entities/route_entity.dart';
import '../repositories/map_repository.dart';

class GetRouteUseCase {
  final MapRepository repository;

  GetRouteUseCase(this.repository);

  Future<List<RouteEntity>> call(List<Point> waypoints) async {
    return repository.getRoutes(waypoints);
  }
}
