import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import '../entities/location_entity.dart';
import '../repositories/map_repository.dart';

class SearchLocationUseCase {
  final MapRepository repository;

  SearchLocationUseCase(this.repository);

  Future<LocationEntity?> call(String query, {Point? proximity}) async {
    return repository.forwardGeocode(query, proximity: proximity);
  }
}
