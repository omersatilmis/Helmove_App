import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import '../entities/location_entity.dart';
import '../repositories/map_repository.dart';

class SearchLocationSuggestionsUseCase {
  final MapRepository repository;

  SearchLocationSuggestionsUseCase(this.repository);

  Future<List<LocationEntity>> call(
    String query, {
    Point? proximity,
    CoordinateBounds? bbox,
    List<String>? types,
    int limit = 6,
  }) {
    return repository.searchLocations(
      query,
      proximity: proximity,
      bbox: bbox,
      types: types,
      limit: limit,
    );
  }
}
