import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:rxdart/rxdart.dart';
import '../../domain/entities/location_entity.dart';
import '../../domain/entities/route_entity.dart';
import '../../domain/usecases/get_route_usecase.dart';
import '../../domain/usecases/search_location_usecase.dart';
import '../../domain/usecases/search_location_suggestions_usecase.dart';
import '../../domain/usecases/reverse_geocode_usecase.dart';
import '../../data/errors/mapbox_exception.dart';
import '../../../ride_history/domain/entities/ride_entity.dart';
import '../../../ride_history/domain/repositories/ride_repository.dart';
import '../../../ride_history/domain/services/ride_recording_service.dart';
import 'map_event.dart';
import 'map_state.dart';
import '../../../../core/utils/navigation_mode_notifier.dart';

export 'map_state.dart';

class MapBloc extends Bloc<MapEvent, MapState> {
  static const String _errorSearchFailedKey = 'map_error_search_failed';
  static const String _errorLocationNotFoundKey = 'map_error_location_not_found';
  static const String _errorConfigurationKey = 'map_error_configuration';
  static const String _errorUnauthorizedKey = 'map_error_unauthorized';
  static const String _errorRateLimitedKey = 'map_error_rate_limited';
  static const String _errorNetworkKey = 'map_error_network';
  static const String _errorInvalidResponseKey = 'map_error_invalid_response';
  static const String _errorUnknownKey = 'map_error_unknown';

  final SearchLocationUseCase _searchLocation;
  final SearchLocationSuggestionsUseCase _searchSuggestions;
  final GetRouteUseCase _getRoute;
  final ReverseGeocodeUseCase _reverseGeocode;
  final RideRecordingService _recordingService;
  final RideRepository _rideRepository;

  StreamSubscription<RidePoint>? _gpsSub;

  Stream<RidePoint> get recordingStream => _recordingService.pointStream;

  MapBloc({
    required SearchLocationUseCase searchLocation,
    required SearchLocationSuggestionsUseCase searchSuggestions,
    required GetRouteUseCase getRoute,
    required ReverseGeocodeUseCase reverseGeocode,
    required RideRecordingService recordingService,
    required RideRepository rideRepository,
  }) : _searchLocation = searchLocation,
       _searchSuggestions = searchSuggestions,
       _getRoute = getRoute,
       _reverseGeocode = reverseGeocode,
       _recordingService = recordingService,
       _rideRepository = rideRepository,
       super(const MapState()) {
    on<MapSearchLocationRequested>(_onSearchLocationRequested);
    on<MapSearchQueryChanged>(
      _onSearchQueryChanged,
      transformer: _debounceSearch(),
    );
    on<MapSearchSuggestionsRequested>(_onSearchSuggestionsRequested);
    on<MapSearchSuggestionSelected>(_onSearchSuggestionSelected);
    on<MapSearchFiltersUpdated>(_onSearchFiltersUpdated);
    on<MapSearchFieldCleared>(_onSearchFieldCleared);
    on<MapRouteRequested>(_onRouteRequested);
    on<MapSharedRouteLoaded>(_onSharedRouteLoaded);
    on<MapPointSelectedFromMap>(_onPointSelectedFromMap);
    on<MapRouteSelectionChanged>(_onRouteSelectionChanged);
    on<MapRouteStepSelected>(_onRouteStepSelected);
    on<MapRoutePoisUpdated>(_onRoutePoisUpdated);
    on<MapRoutePoiSelected>(_onRoutePoiSelected);
    on<MapClearRoutingRequested>(_onClearRoutingRequested);
    on<MapCameraMoved>(_onCameraMoved);
    on<MapSelectLocation>(_onSelectLocation);
    on<MapAddStopViewToggled>(_onAddStopViewToggled);
    on<MapToggleStopSelectionMode>(_onToggleStopSelectionMode);
    on<MapAddStopRequested>(_onAddStopRequested);
    on<MapStopsReordered>(_onStopsReordered);
    on<MapAutoFillStartFromGps>(_onAutoFillStartFromGps);
    on<MapStartNavigationPressed>(_onStartNavigation);
    on<MapStopNavigationPressed>(_onStopNavigation);
    on<MapRideSaveAcknowledged>((_, emit) => emit(state.copyWith(clearRideSaved: true)));
  }

  @override
  Future<void> close() async {
    await _gpsSub?.cancel();
    await super.close();
  }

  EventTransformer<MapSearchQueryChanged> _debounceSearch() {
    return (events, mapper) => events
        .debounceTime(const Duration(milliseconds: 350))
        .switchMap(mapper);
  }

  Future<void> _onSearchLocationRequested(
    MapSearchLocationRequested event,
    Emitter<MapState> emit,
  ) async {
    emit(
      state.copyWith(
        isSearching: true,
        isSuggesting: false,
        suggestions: const [],
        lastQuery: '',
        searchTargetIsStart: event.isStart,
        error: null,
      ),
    );
    LocationEntity? result;
    try {
      result = await _searchLocation(event.query, proximity: state.mapCenter);
    } on MapboxException catch (e, st) {
      _logMapboxError(e, st);
      emit(
        state.copyWith(
          status: MapStatus.error,
          error: _mapboxErrorMessage(e),
          isSearching: false,
        ),
      );
      return;
    } catch (e, st) {
      _logUnexpectedError('searchLocation', e, st);
      emit(
        state.copyWith(
          status: MapStatus.error,
          error: _errorSearchFailedKey,
          isSearching: false,
        ),
      );
      return;
    }

    if (result == null) {
      emit(
        state.copyWith(
          status: MapStatus.error,
          error: _errorLocationNotFoundKey,
          isSearching: false,
        ),
      );
      return;
    }

    if (event.isStart) {
      emit(
        state.copyWith(
          startPoint: result,
          status: MapStatus.success,
          isSearching: false,
          isRouteActive: false,
          routeOptions: const [],
          selectedRouteIndex: 0,
          clearSelectedStepIndex: true,
          routePois: const [],
          clearSelectedPoiIndex: true,
        ),
      );
    } else {
      emit(
        state.copyWith(
          endPoint: result,
          status: MapStatus.success,
          isSearching: false,
          isRouteActive: false,
          routeOptions: const [],
          selectedRouteIndex: 0,
          clearSelectedStepIndex: true,
          routePois: const [],
          clearSelectedPoiIndex: true,
        ),
      );
    }
  }

  Future<void> _onSearchQueryChanged(
    MapSearchQueryChanged event,
    Emitter<MapState> emit,
  ) async {
    await _fetchSuggestions(
      query: event.query,
      isStart: event.isStart,
      isStop: event.isStop,
      emit: emit,
      force: false,
    );
  }

  Future<void> _onSearchSuggestionsRequested(
    MapSearchSuggestionsRequested event,
    Emitter<MapState> emit,
  ) async {
    await _fetchSuggestions(
      query: event.query,
      isStart: event.isStart,
      isStop: event.isStop,
      emit: emit,
      force: true,
    );
  }

  Future<void> _onSearchSuggestionSelected(
    MapSearchSuggestionSelected event,
    Emitter<MapState> emit,
  ) async {
    emit(
      state.copyWith(
        suggestions: const [],
        isSuggesting: false,
        lastQuery: '',
        searchTargetIsStart: event.isStart,
        searchTargetIsStop: event.isStop,
        isSearching: false,
      ),
    );

    if (event.isStart) {
      emit(
        state.copyWith(
          startPoint: event.location,
          status: MapStatus.success,
          isRouteActive: false,
          routeOptions: const [],
          selectedRouteIndex: 0,
          clearSelectedStepIndex: true,
          routePois: const [],
          clearSelectedPoiIndex: true,
        ),
      );
    } else if (event.isStop) {
      add(MapAddStopRequested(event.location));
    } else {
      emit(
        state.copyWith(
          endPoint: event.location,
          status: MapStatus.success,
          isRouteActive: false,
          routeOptions: const [],
          selectedRouteIndex: 0,
          clearSelectedStepIndex: true,
          routePois: const [],
          clearSelectedPoiIndex: true,
        ),
      );
    }

    // If we now have both endpoints, auto-fetch the route
    if (!event.isStop && state.startPoint != null && state.endPoint != null) {
      add(MapRouteRequested());
    }
  }

  void _onSearchFiltersUpdated(
    MapSearchFiltersUpdated event,
    Emitter<MapState> emit,
  ) {
    emit(state.copyWith(searchFilters: event.filters));

    final query = state.lastQuery.trim();
    if (query.length < 2) return;
    add(
      MapSearchSuggestionsRequested(
        query: query,
        isStart: state.searchTargetIsStart,
        isStop: state.searchTargetIsStop,
      ),
    );
  }

  void _onSearchFieldCleared(
    MapSearchFieldCleared event,
    Emitter<MapState> emit,
  ) {
    emit(
      state.copyWith(
        clearStartPoint: event.isStart,
        clearEndPoint: !event.isStart,
        isSearching: false,
        isSuggesting: false,
        suggestions: const [],
        lastQuery: '',
        isRouting: false,
        isRouteActive: false,
        routeOptions: const [],
        selectedRouteIndex: 0,
        clearSelectedStepIndex: true,
        routePois: const [],
        clearSelectedPoiIndex: true,
        error: null,
      ),
    );
  }

  Future<void> _onRouteRequested(
    MapRouteRequested event,
    Emitter<MapState> emit,
  ) async {
    final start = state.startPoint;
    final end = state.endPoint;
    if (start == null || end == null) {
      emit(
        state.copyWith(
          status: MapStatus.error,
          error: 'Başlangıç ve bitiş seçin.',
          isRouting: false,
        ),
      );
      return;
    }

    // Destination card'ı hemen kapat — rota yüklenirken eski menü görünmesin.
    if (state.selectedLocation != null) {
      emit(state.copyWith(selectedLocation: null));
    }

    await _maybeRequestRoutes(emit);
  }

  void _onSharedRouteLoaded(
    MapSharedRouteLoaded event,
    Emitter<MapState> emit,
  ) {
    emit(
      state.copyWith(
        startPoint: event.start,
        endPoint: event.end,
        stops: event.stops,
        isRouteActive: false,
        routeOptions: const [],
        selectedRouteIndex: 0,
        clearSelectedStepIndex: true,
        routePois: const [],
        clearSelectedPoiIndex: true,
        isAddStopVisible: false,
        isSelectingStopFromMap: false,
        selectedLocation: null,
      ),
    );

    add(MapRouteRequested());
  }

  Future<void> _fetchSuggestions({
    required String query,
    required bool isStart,
    bool isStop = false,
    required Emitter<MapState> emit,
    required bool force,
  }) async {
    final trimmed = query.trim();
    final isTargetChanged =
        state.searchTargetIsStart != isStart ||
        state.searchTargetIsStop != isStop;
    final isDuplicateQuery =
        !force && trimmed == state.lastQuery && !isTargetChanged;

    emit(
      state.copyWith(
        lastQuery: trimmed,
        searchTargetIsStart: isStart,
        searchTargetIsStop: isStop,
      ),
    );

    if (trimmed.length < 2) {
      emit(state.copyWith(isSuggesting: false, suggestions: const []));
      return;
    }

    if (isDuplicateQuery &&
        (state.isSuggesting || state.suggestions.isNotEmpty)) {
      return;
    }

    emit(state.copyWith(isSuggesting: true, error: null));

    try {
      final filters = state.searchFilters;
      final proximity = filters.useProximity ? state.mapCenter : null;
      final bbox = filters.useMapBounds ? state.mapBounds : null;
      final types = filters.types.isEmpty ? null : filters.types.toList();

      final results = await _searchSuggestions(
        trimmed,
        proximity: proximity,
        bbox: bbox,
        types: types,
        limit: filters.limit,
      );

      emit(state.copyWith(suggestions: results, isSuggesting: false));
    } on MapboxException catch (e, st) {
      _logMapboxError(e, st);
      emit(
        state.copyWith(
          suggestions: const [],
          isSuggesting: false,
          error: _mapboxErrorMessage(e),
        ),
      );
    } catch (e, st) {
      _logUnexpectedError('searchSuggestions', e, st);
      emit(
        state.copyWith(
          suggestions: const [],
          isSuggesting: false,
          error: 'Arama önerileri alınamadı.',
        ),
      );
    }
  }

  Future<void> _onPointSelectedFromMap(
    MapPointSelectedFromMap event,
    Emitter<MapState> emit,
  ) async {
    emit(
      state.copyWith(
        isSearching: true,
        isSuggesting: false,
        suggestions: const [],
        error: null,
      ),
    );

    String label;
    if (event.label != null && event.label!.isNotEmpty) {
      label = event.label!;
    } else {
      try {
        final geocoded = await _reverseGeocode(event.point);
        label = geocoded?.label ??
            '${event.point.coordinates.lat.toStringAsFixed(5)}, ${event.point.coordinates.lng.toStringAsFixed(5)}';
      } on MapboxException catch (e, st) {
        _logMapboxError(e, st);
        label =
            '${event.point.coordinates.lat.toStringAsFixed(5)}, ${event.point.coordinates.lng.toStringAsFixed(5)}';
      } catch (e, st) {
        _logUnexpectedError('reverseGeocode', e, st);
        label =
            '${event.point.coordinates.lat.toStringAsFixed(5)}, ${event.point.coordinates.lng.toStringAsFixed(5)}';
      }
    }

    final result = LocationEntity(point: event.point, label: label);

    if (event.isStart) {
      emit(
        state.copyWith(
          startPoint: result,
          status: MapStatus.success,
          isSearching: false,
          isRouteActive: false,
          routeOptions: const [],
          selectedRouteIndex: 0,
          clearSelectedStepIndex: true,
          routePois: const [],
          clearSelectedPoiIndex: true,
        ),
      );
    } else {
      emit(
        state.copyWith(
          endPoint: result,
          status: MapStatus.success,
          isSearching: false,
          isRouteActive: false,
          routeOptions: const [],
          selectedRouteIndex: 0,
          clearSelectedStepIndex: true,
          routePois: const [],
          clearSelectedPoiIndex: true,
        ),
      );
    }
  }

  void _onRouteSelectionChanged(
    MapRouteSelectionChanged event,
    Emitter<MapState> emit,
  ) {
    emit(
      state.copyWith(
        selectedRouteIndex: event.index,
        clearSelectedStepIndex: true,
        routePois: const [],
        clearSelectedPoiIndex: true,
      ),
    );
  }

  void _onRouteStepSelected(
    MapRouteStepSelected event,
    Emitter<MapState> emit,
  ) {
    emit(
      state.copyWith(
        selectedStepIndex: event.index,
        clearSelectedStepIndex: event.index == null,
      ),
    );
  }

  void _onRoutePoisUpdated(MapRoutePoisUpdated event, Emitter<MapState> emit) {
    emit(state.copyWith(routePois: event.pois, clearSelectedPoiIndex: true));
  }

  void _onRoutePoiSelected(MapRoutePoiSelected event, Emitter<MapState> emit) {
    emit(
      state.copyWith(
        selectedPoiIndex: event.index,
        clearSelectedPoiIndex: event.index == null,
      ),
    );
  }

  void _onClearRoutingRequested(
    MapClearRoutingRequested event,
    Emitter<MapState> emit,
  ) {
    emit(MapState(mapCenter: state.mapCenter));
  }

  void _onToggleStopSelectionMode(
    MapToggleStopSelectionMode event,
    Emitter<MapState> emit,
  ) {
    emit(state.copyWith(
      isSelectingStopFromMap: event.isSelecting,
      isAddStopVisible: !event.isSelecting && state.isAddStopVisible,
      selectedLocation: event.isSelecting ? null : state.selectedLocation,
    ));
  }

  void _onCameraMoved(MapCameraMoved event, Emitter<MapState> emit) {
    emit(
      state.copyWith(
        mapCenter: event.center,
        mapBounds: event.bounds ?? state.mapBounds,
      ),
    );
  }

  Future<void> _onSelectLocation(
    MapSelectLocation event,
    Emitter<MapState> emit,
  ) async {
    if (event.location == null) {
      emit(state.copyWith(selectedLocation: null));
      return;
    }

    final label = event.location!.label.trim();
    final shouldReverseGeocode =
        event.preferReverseGeocode || _isGenericLabel(label);

    // Emit initial selection
    emit(
      state.copyWith(
        selectedLocation: event.location,
        isGeocoding: shouldReverseGeocode,
      ),
    );

    // If it's a raw coordinate (generic label), try to get the real address
    if (shouldReverseGeocode) {
      try {
        final geocodedLocation = await _reverseGeocode(
          event.location!.point,
          types: event.reverseGeocodeTypes,
        );
        if (geocodedLocation != null && !isClosed) {
          if (_isGenericLabel(label)) {
            emit(
              state.copyWith(
                selectedLocation: geocodedLocation,
                isGeocoding: false,
              ),
            );
          } else {
            final current = event.location!;
            emit(
              state.copyWith(
                selectedLocation: current.copyWith(
                  subtitle: geocodedLocation.subtitle,
                  placeName: current.placeName ?? geocodedLocation.placeName,
                  context: current.context ?? geocodedLocation.context,
                ),
                isGeocoding: false,
              ),
            );
          }
        } else if (!isClosed) {
          emit(state.copyWith(isGeocoding: false));
        }
      } on MapboxException catch (e, st) {
        _logMapboxError(e, st);
        if (!isClosed) emit(state.copyWith(isGeocoding: false));
      } catch (e, st) {
        _logUnexpectedError('reverseGeocode', e, st);
        if (!isClosed) emit(state.copyWith(isGeocoding: false));
      }
    }
  }

  void _onAddStopViewToggled(
    MapAddStopViewToggled event,
    Emitter<MapState> emit,
  ) {
    emit(state.copyWith(isAddStopVisible: event.visible));
  }

  bool _isGenericLabel(String label) {
    final trimmed = label.trim();
    if (trimmed.isEmpty) return true;
    if (trimmed == LocationEntity.selectedLocationLabel ||
        trimmed == 'Secili Konum') {
      return true;
    }
    final coordRegex = RegExp(r'^-?\d+(\.\d+)?\\s*,\\s*-?\d+(\\.\\d+)?$');
    return coordRegex.hasMatch(trimmed);
  }

  Future<void> _maybeRequestRoutes(Emitter<MapState> emit) async {
    final start = state.startPoint;
    final end = state.endPoint;
    if (start == null || end == null) return;

    emit(state.copyWith(isRouting: true, routeNeedsUpdate: false, error: null));
    late final List<RouteEntity> routes;
    try {
      final waypoints = [
        state.startPoint!.point,
        ...state.stops.map((s) => s.point),
        state.endPoint!.point,
      ];
      routes = await _getRoute(waypoints);
    } on MapboxException catch (e, st) {
      _logMapboxError(e, st);
      emit(
        state.copyWith(
          status: MapStatus.error,
          error: _mapboxErrorMessage(e),
          isRouting: false,
          isRouteActive: false,
          routePois: const [],
          clearSelectedPoiIndex: true,
          routeOptions: const [],
          selectedRouteIndex: 0,
          clearSelectedStepIndex: true,
        ),
      );
      return;
    } catch (e, st) {
      _logUnexpectedError('getRoute', e, st);
      emit(
        state.copyWith(
          status: MapStatus.error,
          error: 'Rota alınamadı.',
          isRouting: false,
          isRouteActive: false,
          routePois: const [],
          clearSelectedPoiIndex: true,
          routeOptions: const [],
          selectedRouteIndex: 0,
          clearSelectedStepIndex: true,
        ),
      );
      return;
    }

    if (routes.isEmpty) {
      emit(
        state.copyWith(
          status: MapStatus.error,
          error: 'Rota bulunamadı',
          isRouting: false,
          isRouteActive: false,
          clearSelectedStepIndex: true,
          routeOptions: const [],
          selectedRouteIndex: 0,
          routePois: const [],
          clearSelectedPoiIndex: true,
        ),
      );
    } else {
      emit(
        state.copyWith(
          routeOptions: routes,
          selectedRouteIndex: 0,
          status: MapStatus.success,
          isRouting: false,
          isRouteActive: true,
          clearSelectedStepIndex: true,
          routePois: const [],
          clearSelectedPoiIndex: true,
          selectedLocation: null,
        ),
      );
    }
  }

  void _logMapboxError(MapboxException exception, StackTrace stackTrace) {
    debugPrint('Mapbox error: $exception');
    debugPrint('$stackTrace');
  }

  void _logUnexpectedError(
    String operation,
    Object error,
    StackTrace stackTrace,
  ) {
    debugPrint('MapBloc $operation error: $error');
    debugPrint('$stackTrace');
  }

  void _onAddStopRequested(
    MapAddStopRequested event,
    Emitter<MapState> emit,
  ) {
    if (state.stops.contains(event.location)) return;

    final updatedStops = List<LocationEntity>.from(state.stops)
      ..add(event.location);
    emit(state.copyWith(
      stops: updatedStops,
      isAddStopVisible: false,
      isSelectingStopFromMap: false,
      selectedLocation: null,
    ));
    add(MapRouteRequested());
  }

  Future<void> _onStopsReordered(
    MapStopsReordered event,
    Emitter<MapState> emit,
  ) async {
    // Tüm noktaları tek bir listede topla
    final List<LocationEntity> allPoints = [];
    if (state.startPoint != null) allPoints.add(state.startPoint!);
    allPoints.addAll(state.stops);
    if (state.endPoint != null) allPoints.add(state.endPoint!);

    if (allPoints.isEmpty) return;

    int newIndex = event.newIndex;
    if (event.oldIndex < newIndex) {
      newIndex -= 1;
    }

    final item = allPoints.removeAt(event.oldIndex);
    allPoints.insert(newIndex, item);

    // Listeyi geri parçala
    final LocationEntity? newStart = allPoints.isNotEmpty ? allPoints.first : null;
    final LocationEntity? newEnd = allPoints.length > 1 ? allPoints.last : null;
    final List<LocationEntity> newStops = allPoints.length > 2 
        ? allPoints.sublist(1, allPoints.length - 1) 
        : [];

    emit(state.copyWith(
      startPoint: newStart,
      endPoint: newEnd,
      stops: newStops,
      routeNeedsUpdate: true,
    ));

    // Rota artık otomatik güncellenmiyor (Kullanıcı "Rota Yenile" basacak)
  }

  String _mapboxErrorMessage(MapboxException exception) {
    switch (exception.type) {
      case MapboxErrorType.configuration:
        return _errorConfigurationKey;
      case MapboxErrorType.unauthorized:
        return _errorUnauthorizedKey;
      case MapboxErrorType.rateLimited:
        return _errorRateLimitedKey;
      case MapboxErrorType.network:
        return _errorNetworkKey;
      case MapboxErrorType.invalidResponse:
        return _errorInvalidResponseKey;
      case MapboxErrorType.unknown:
        return _errorUnknownKey;
    }
  }

  Future<void> _onAutoFillStartFromGps(
    MapAutoFillStartFromGps event,
    Emitter<MapState> emit,
  ) async {
    if (state.startPoint != null) return;

    try {
      final serviceEnabled = await geo.Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) { return; }

      final permission = await geo.Geolocator.checkPermission();
      if (permission == geo.LocationPermission.denied ||
          permission == geo.LocationPermission.deniedForever) { return; }

      final position = await geo.Geolocator.getCurrentPosition(
        locationSettings: const geo.LocationSettings(
          accuracy: geo.LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      final point = Point(
        coordinates: Position(position.longitude, position.latitude),
      );

      LocationEntity? location;
      try {
        location = await _reverseGeocode(point);
      } catch (_) {}

      location ??= LocationEntity(
        point: point,
        label:
            '${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}',
      );

      if (!isClosed && state.startPoint == null) {
        emit(state.copyWith(startPoint: location, status: MapStatus.success));
      }
    } catch (_) {
      // GPS auto-fill is best-effort; silently ignore
    }
  }

  Future<void> _onStartNavigation(
    MapStartNavigationPressed event,
    Emitter<MapState> emit,
  ) async {
    if (state.isNavigating) return;
    navigationModeNotifier.value = true;
    emit(state.copyWith(isNavigating: true));
    try {
      await _recordingService.start();
    } catch (e) {
      debugPrint('RideRecordingService.start error: $e');
    }
  }

  Future<void> _onStopNavigation(
    MapStopNavigationPressed event,
    Emitter<MapState> emit,
  ) async {
    if (!state.isNavigating) return;
    navigationModeNotifier.value = false;
    emit(state.copyWith(isNavigating: false, clearCurrentSpeedKmh: true));
    try {
      final ride = await _recordingService.stop();
      if (ride != null && !isClosed) {
        try {
          await _rideRepository.createRide(ride);
          if (!isClosed) emit(state.copyWith(rideSaved: true));
        } catch (e) {
          debugPrint('Failed to save ride: $e');
          if (!isClosed) emit(state.copyWith(rideSaved: false));
        }
      }
    } catch (e) {
      debugPrint('RideRecordingService.stop error: $e');
    }
  }
}
