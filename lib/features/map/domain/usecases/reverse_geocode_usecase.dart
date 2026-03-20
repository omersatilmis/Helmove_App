import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import '../entities/location_entity.dart';
import '../repositories/map_repository.dart';

class ReverseGeocodeUseCase {
  final MapRepository repository;

  ReverseGeocodeUseCase(this.repository);

  Future<LocationEntity?> call(Point point, {List<String>? types}) async {
    return repository.reverseGeocode(point, types: types);
  }
}
