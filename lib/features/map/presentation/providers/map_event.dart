import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import '../../domain/entities/location_entity.dart';
import 'map_state.dart';

abstract class MapEvent {}

class MapSearchLocationRequested extends MapEvent {
  final String query;
  final bool isStart;
  final bool isStop;

  MapSearchLocationRequested({
    required this.query,
    required this.isStart,
    this.isStop = false,
  });
}

class MapSearchQueryChanged extends MapEvent {
  final String query;
  final bool isStart;
  final bool isStop;

  MapSearchQueryChanged({
    required this.query,
    required this.isStart,
    this.isStop = false,
  });
}

class MapSearchSuggestionsRequested extends MapEvent {
  final String query;
  final bool isStart;
  final bool isStop;

  MapSearchSuggestionsRequested({
    required this.query,
    required this.isStart,
    this.isStop = false,
  });
}

class MapSearchSuggestionSelected extends MapEvent {
  final LocationEntity location;
  final bool isStart;
  final bool isStop;

  MapSearchSuggestionSelected({
    required this.location,
    required this.isStart,
    this.isStop = false,
  });
}

class MapAddStopRequested extends MapEvent {
  final LocationEntity location;
  MapAddStopRequested(this.location);
}

class MapSearchFiltersUpdated extends MapEvent {
  final MapSearchFilters filters;

  MapSearchFiltersUpdated(this.filters);
}

class MapSearchFieldCleared extends MapEvent {
  final bool isStart;

  MapSearchFieldCleared({required this.isStart});
}

class MapRouteRequested extends MapEvent {}

class MapSharedRouteLoaded extends MapEvent {
  final LocationEntity start;
  final LocationEntity end;
  final List<LocationEntity> stops;

  MapSharedRouteLoaded({
    required this.start,
    required this.end,
    this.stops = const [],
  });
}

class MapPointSelectedFromMap extends MapEvent {
  final Point point;
  final bool isStart;
  final String? label;

  MapPointSelectedFromMap({
    required this.point,
    required this.isStart,
    this.label,
  });
}

class MapRouteSelectionChanged extends MapEvent {
  final int index;

  MapRouteSelectionChanged(this.index);
}

class MapRouteStepSelected extends MapEvent {
  final int? index;

  MapRouteStepSelected(this.index);
}

class MapRoutePoisUpdated extends MapEvent {
  final List<LocationEntity> pois;

  MapRoutePoisUpdated(this.pois);
}

class MapRoutePoiSelected extends MapEvent {
  final int? index;

  MapRoutePoiSelected(this.index);
}

class MapClearRoutingRequested extends MapEvent {}

class MapStopsReordered extends MapEvent {
  final int oldIndex;
  final int newIndex;

  MapStopsReordered({required this.oldIndex, required this.newIndex});
}

class MapCameraMoved extends MapEvent {
  final Point center;
  final CoordinateBounds? bounds;

  MapCameraMoved(this.center, {this.bounds});
}

class MapSelectLocation extends MapEvent {
  final LocationEntity? location;
  final bool preferReverseGeocode;
  final List<String>? reverseGeocodeTypes;

  MapSelectLocation(
    this.location, {
    this.preferReverseGeocode = false,
    this.reverseGeocodeTypes,
  });
}

class MapAddStopViewToggled extends MapEvent {
  final bool visible;
  MapAddStopViewToggled(this.visible);
}

class MapToggleStopSelectionMode extends MapEvent {
  final bool isSelecting;
  MapToggleStopSelectionMode(this.isSelecting);
}
