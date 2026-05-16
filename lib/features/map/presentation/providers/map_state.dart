import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import '../../domain/entities/location_entity.dart';
import '../../domain/entities/route_entity.dart';

enum MapStatus { initial, loading, success, error }

class MapSearchFilters {
  final bool useProximity;
  final bool useMapBounds;
  final Set<String> types;
  final int limit;

  const MapSearchFilters({
    this.useProximity = true,
    this.useMapBounds = false,
    this.types = const <String>{},
    this.limit = 6,
  });

  MapSearchFilters copyWith({
    bool? useProximity,
    bool? useMapBounds,
    Set<String>? types,
    int? limit,
  }) {
    return MapSearchFilters(
      useProximity: useProximity ?? this.useProximity,
      useMapBounds: useMapBounds ?? this.useMapBounds,
      types: types ?? this.types,
      limit: limit ?? this.limit,
    );
  }
}

class MapState {
  final MapStatus status;
  final LocationEntity? startPoint;
  final LocationEntity? endPoint;
  final List<RouteEntity> routeOptions;
  final int selectedRouteIndex;
  final int? selectedStepIndex;
  final bool isSearching;
  final bool isRouting;
  final bool isRouteActive;
  final bool isSuggesting;
  final List<LocationEntity> suggestions;
  final String lastQuery;
  final bool searchTargetIsStart;
  final MapSearchFilters searchFilters;
  final CoordinateBounds? mapBounds;
  final Point? mapCenter;
  final LocationEntity? selectedLocation;
  final List<LocationEntity> routePois;
  final int? selectedPoiIndex;
  final bool isAddStopVisible;
  final List<LocationEntity> stops;
  final bool searchTargetIsStop;
  final bool routeNeedsUpdate;
  final bool isGeocoding;
  final bool isSelectingStopFromMap;
  final String? error;
  final bool isNavigating;
  final double? currentSpeedKmh;
  final bool? rideSaved;

  const MapState({
    this.status = MapStatus.initial,
    this.startPoint,
    this.endPoint,
    this.routeOptions = const [],
    this.selectedRouteIndex = 0,
    this.selectedStepIndex,
    this.isSearching = false,
    this.isRouting = false,
    this.isRouteActive = false,
    this.isSuggesting = false,
    this.suggestions = const [],
    this.lastQuery = '',
    this.searchTargetIsStart = true,
    this.searchFilters = const MapSearchFilters(),
    this.mapBounds,
    this.mapCenter,
    this.selectedLocation,
    this.routePois = const [],
    this.selectedPoiIndex,
    this.isAddStopVisible = false,
    this.stops = const [],
    this.searchTargetIsStop = false,
    this.routeNeedsUpdate = false,
    this.isGeocoding = false,
    this.isSelectingStopFromMap = false,
    this.error,
    this.isNavigating = false,
    this.currentSpeedKmh,
    this.rideSaved,
  });

  MapState copyWith({
    MapStatus? status,
    LocationEntity? startPoint,
    LocationEntity? endPoint,
    bool clearStartPoint = false,
    bool clearEndPoint = false,
    List<RouteEntity>? routeOptions,
    int? selectedRouteIndex,
    int? selectedStepIndex,
    bool clearSelectedStepIndex = false,
    bool? isSearching,
    bool? isRouting,
    bool? isRouteActive,
    bool? isSuggesting,
    List<LocationEntity>? suggestions,
    String? lastQuery,
    bool? searchTargetIsStart,
    MapSearchFilters? searchFilters,
    CoordinateBounds? mapBounds,
    Point? mapCenter,
    LocationEntity? selectedLocation,
    List<LocationEntity>? routePois,
    int? selectedPoiIndex,
    bool clearSelectedPoiIndex = false,
    bool? isAddStopVisible,
    List<LocationEntity>? stops,
    bool? searchTargetIsStop,
    bool? routeNeedsUpdate,
    bool? isGeocoding,
    bool? isSelectingStopFromMap,
    String? error,
    bool? isNavigating,
    double? currentSpeedKmh,
    bool clearCurrentSpeedKmh = false,
    bool? rideSaved,
    bool clearRideSaved = false,
  }) {
    return MapState(
      status: status ?? this.status,
      startPoint: clearStartPoint ? null : (startPoint ?? this.startPoint),
      endPoint: clearEndPoint ? null : (endPoint ?? this.endPoint),
      routeOptions: routeOptions ?? this.routeOptions,
      selectedRouteIndex: selectedRouteIndex ?? this.selectedRouteIndex,
      selectedStepIndex:
          clearSelectedStepIndex ? null : (selectedStepIndex ?? this.selectedStepIndex),
      isSearching: isSearching ?? this.isSearching,
      isRouting: isRouting ?? this.isRouting,
      isRouteActive: isRouteActive ?? this.isRouteActive,
      isSuggesting: isSuggesting ?? this.isSuggesting,
      suggestions: suggestions ?? this.suggestions,
      lastQuery: lastQuery ?? this.lastQuery,
      searchTargetIsStart: searchTargetIsStart ?? this.searchTargetIsStart,
      searchFilters: searchFilters ?? this.searchFilters,
      mapBounds: mapBounds ?? this.mapBounds,
      mapCenter: mapCenter ?? this.mapCenter,
      selectedLocation: selectedLocation ?? this.selectedLocation,
      routePois: routePois ?? this.routePois,
      selectedPoiIndex:
          clearSelectedPoiIndex ? null : (selectedPoiIndex ?? this.selectedPoiIndex),
      isAddStopVisible: isAddStopVisible ?? this.isAddStopVisible,
      stops: stops ?? this.stops,
      searchTargetIsStop: searchTargetIsStop ?? this.searchTargetIsStop,
      routeNeedsUpdate: routeNeedsUpdate ?? this.routeNeedsUpdate,
      isGeocoding: isGeocoding ?? this.isGeocoding,
      isSelectingStopFromMap: isSelectingStopFromMap ?? this.isSelectingStopFromMap,
      error: error,
      isNavigating: isNavigating ?? this.isNavigating,
      currentSpeedKmh: clearCurrentSpeedKmh ? null : (currentSpeedKmh ?? this.currentSpeedKmh),
      rideSaved: clearRideSaved ? null : (rideSaved ?? this.rideSaved),
    );
  }
}
