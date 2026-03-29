import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:helmove/l10n/app_localizations.dart';
import 'package:helmove/core/config/app_feature_flags.dart';
import 'package:helmove/core/services/deep_link_store.dart';
import '../../config/mapbox_config.dart';
import '../../domain/entities/location_entity.dart';
import '../../domain/entities/route_entity.dart';
import '../providers/map_bloc.dart';
import '../providers/map_event.dart';
import '../widgets/map_search_bar.dart';
import '../widgets/map_bottom_sheet.dart';
import '../widgets/route_poi_panel.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  static const String _styleUri = 'mapbox://styles/mapbox/navigation-night-v1';
  static const int _diskQuotaBytes = 200 * 1024 * 1024;
  static const int _prefetchLowResDelta = 2;
  static const int _prefetchNormalDelta = 0;
  static const double _maxZoomLevel = 16.0;
  static const Duration _cacheDebounce = Duration(milliseconds: 700);
  static const Duration _compassUpdateInterval = Duration(milliseconds: 50);
  static const double _compassDeltaThresholdDeg = 0.8;
  static const String _routeRegionPrefix = 'route_';
  static const double _fabRightPadding = 16.0;
  static const double _fabSpacing = 10.0;

  final ValueNotifier<bool> _isLoadingLocation = ValueNotifier(false);
  MapboxMap? _mapboxMap;
  TileStore? _tileStore;
  OfflineManager? _offlineManager;
  Timer? _cacheTimer;
  bool _cacheInFlight = false;
  CameraOptions? _lastCamera;
  String? _lastTileRegionId;
  double _compassRotation = 0.0;
  double _lastBearingDeg = 0.0;
  DateTime _lastCompassUpdateAt = DateTime.fromMillisecondsSinceEpoch(0);
  String? _lastActiveRouteKey;

  CircleAnnotationManager? _markerManager;
  CircleAnnotation? _startMarker;
  CircleAnnotation? _endMarker;
  PolylineAnnotationManager? _routeLineManager;
  List<PolylineAnnotation> _routeLines = [];
  PolylineAnnotationManager? _stepLineManager;
  List<PolylineAnnotation> _stepLines = [];
  CircleAnnotationManager? _poiMarkerManager;
  List<CircleAnnotation> _poiMarkers = [];
  Timer? _poiScanTimer;
  bool _poiScanInFlight = false;
  String? _lastPoiSignature;
  StreamSubscription<Uri>? _deepLinkSub;

  // Default Center: Istanbul / Turkey (longitude, latitude)
  final Point _defaultCenter = Point(coordinates: Position(28.9784, 41.0082));

  @override
  void initState() {
    super.initState();
    final token = MapboxConfig.accessToken;
    if (token.isEmpty) {
      debugPrint('Mapbox access token is missing.');
    }
    MapboxOptions.setAccessToken(token);
    MapboxMapsOptions.setTileStoreUsageMode(TileStoreUsageMode.READ_AND_UPDATE);
    _initTileStore();
    _initStylePack();
    _attachDeepLinkListener();
  }

  void _attachDeepLinkListener() {
    _deepLinkSub = DeepLinkStore.instance.stream.listen(_handleDeepLink);
    final pending = DeepLinkStore.instance.consume();
    if (pending != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleDeepLink(pending);
      });
    }
  }

  Future<void> _initTileStore() async {
    _tileStore = await TileStore.createDefault();
    _tileStore?.setDiskQuota(_diskQuotaBytes);
  }

  Future<void> _initStylePack() async {
    _offlineManager = await OfflineManager.create();
    try {
      await _offlineManager?.stylePack(_styleUri);
    } catch (_) {
      final options = StylePackLoadOptions(
        glyphsRasterizationMode:
            GlyphsRasterizationMode.IDEOGRAPHS_RASTERIZED_LOCALLY,
        acceptExpired: true,
      );
      await _offlineManager?.loadStylePack(_styleUri, options, null);
    }
  }

  @override
  void dispose() {
    _cacheTimer?.cancel();
    _poiScanTimer?.cancel();
    _isLoadingLocation.dispose();
    _deepLinkSub?.cancel();
    super.dispose();
  }

  void _handleDeepLink(Uri uri) {
    if (!mounted) {
      return;
    }
    if (uri.scheme != 'helmove' || uri.host != 'share') {
      return;
    }

    final type = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : '';
    if (type == 'location') {
      final lat = double.tryParse(uri.queryParameters['lat'] ?? '');
      final lng = double.tryParse(uri.queryParameters['lng'] ?? '');
      if (lat == null || lng == null) {
        return;
      }
      final label = uri.queryParameters['label'];
      final location = _buildLocation(lat, lng, label: label);
      final bloc = context.read<MapBloc>();
      bloc.add(MapClearRoutingRequested());
      bloc.add(
        MapSelectLocation(
          location,
          preferReverseGeocode: label == null || label.trim().isEmpty,
        ),
      );
      return;
    }

    if (type == 'route') {
      final startLat = double.tryParse(uri.queryParameters['startLat'] ?? '');
      final startLng = double.tryParse(uri.queryParameters['startLng'] ?? '');
      final endLat = double.tryParse(uri.queryParameters['endLat'] ?? '');
      final endLng = double.tryParse(uri.queryParameters['endLng'] ?? '');
      if (startLat == null || startLng == null || endLat == null || endLng == null) {
        return;
      }

      final startLabel = uri.queryParameters['startLabel'];
      final endLabel = uri.queryParameters['endLabel'];
      final start = _buildLocation(startLat, startLng, label: startLabel);
      final end = _buildLocation(endLat, endLng, label: endLabel);

      final stopsParam = uri.queryParameters['stops'];
      final stops = _parseStops(stopsParam);

      final bloc = context.read<MapBloc>();
      bloc.add(MapClearRoutingRequested());
      bloc.add(MapSharedRouteLoaded(start: start, end: end, stops: stops));
      return;
    }
  }

  LocationEntity _buildLocation(double lat, double lng, {String? label}) {
    final resolvedLabel = (label == null || label.trim().isEmpty)
        ? '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}'
        : label;
    return LocationEntity(
      point: Point(coordinates: Position(lng, lat)),
      label: resolvedLabel,
    );
  }

  List<LocationEntity> _parseStops(String? stopsParam) {
    if (stopsParam == null || stopsParam.trim().isEmpty) {
      return const [];
    }

    final List<LocationEntity> stops = [];
    final items = stopsParam.split('|');
    for (final item in items) {
      final parts = item.split(',');
      if (parts.length != 2) {
        continue;
      }
      final lat = double.tryParse(parts[0]);
      final lng = double.tryParse(parts[1]);
      if (lat == null || lng == null) {
        continue;
      }
      stops.add(_buildLocation(lat, lng));
    }

    return stops;
  }

  void _onMapCreated(MapboxMap mapboxMap) {
    _mapboxMap = mapboxMap;
    _mapboxMap?.setPrefetchZoomDelta(_prefetchLowResDelta);
    unawaited(
      _mapboxMap?.setBounds(
        CameraBoundsOptions(maxZoom: _maxZoomLevel, minZoom: 3.0),
      ),
    );
    unawaited(_initAnnotationManagers());
    _mapboxMap?.location.updateSettings(
      LocationComponentSettings(
        enabled: true,
        pulsingEnabled: false,
        showAccuracyRing: false,
      ),
    );
    _updateMapPadding();
    unawaited(
      _mapboxMap?.compass.updateSettings(
        CompassSettings(enabled: false, visibility: false),
      ),
    );
  }

  void _updateMapPadding() {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    _mapboxMap?.setCamera(
      CameraOptions(
        padding: MbxEdgeInsets(top: 0, left: 0, bottom: bottomInset, right: 0),
      ),
    );
  }

  void _onMapLoaded(MapLoadedEventData _) {
    _mapboxMap?.setPrefetchZoomDelta(_prefetchNormalDelta);
    unawaited(_disable3dBuildings());
  }

  void _onCameraChanged(CameraChangedEventData event) {
    final now = DateTime.now();
    final bearing = event.cameraState.bearing;
    final delta = (bearing - _lastBearingDeg).abs();
    final shouldUpdate =
        delta >= _compassDeltaThresholdDeg ||
        now.difference(_lastCompassUpdateAt) >= _compassUpdateInterval;

    if (!shouldUpdate) return;

    _lastBearingDeg = bearing;
    _lastCompassUpdateAt = now;
    _updateCompassRotation(bearing);
  }

  void _onMapIdle(MapIdleEventData _) async {
    await _captureCameraState();

    // Update MapCenter in Bloc for search proximity
    if (mounted && _mapboxMap != null) {
      final mapboxMap = _mapboxMap!;
      final cameraState = await mapboxMap.getCameraState();
      final camera = CameraOptions(
        center: cameraState.center,
        zoom: cameraState.zoom,
        bearing: cameraState.bearing,
        pitch: cameraState.pitch,
        padding: cameraState.padding,
      );
      final bounds = await mapboxMap.coordinateBoundsForCamera(camera);
      if (mounted) {
        context.read<MapBloc>().add(
          MapCameraMoved(cameraState.center, bounds: bounds),
        );
      }
    }
  }

  Future<void> _captureCameraState() async {
    final mapboxMap = _mapboxMap;
    if (mapboxMap == null) return;
    final cameraState = await mapboxMap.getCameraState();
    _lastCamera = CameraOptions(
      center: cameraState.center,
      zoom: cameraState.zoom,
      bearing: cameraState.bearing,
      pitch: cameraState.pitch,
      padding: cameraState.padding,
    );
  }

  void _updateCompassRotation(double bearing) {
    final next = -bearing * math.pi / 180.0;
    if ((next - _compassRotation).abs() < 0.001) return;
    if (!mounted) return;
    setState(() {
      _compassRotation = next;
    });
  }

  Future<void> _disable3dBuildings() async {
    final mapboxMap = _mapboxMap;
    if (mapboxMap == null) return;
    final layers = await mapboxMap.style.getStyleLayers();
    for (final layer in layers) {
      if (layer == null) continue;
      if (layer.type == 'fill-extrusion') {
        await mapboxMap.style.removeStyleLayer(layer.id);
      }
    }
  }

  Future<void> _initAnnotationManagers() async {
    final mapboxMap = _mapboxMap;
    if (mapboxMap == null) return;
    _markerManager = await mapboxMap.annotations
        .createCircleAnnotationManager();
    _routeLineManager = await mapboxMap.annotations
        .createPolylineAnnotationManager();
    await _routeLineManager?.setLineCap(LineCap.ROUND);
    await _routeLineManager?.setLineJoin(LineJoin.ROUND);
    _stepLineManager = await mapboxMap.annotations
        .createPolylineAnnotationManager();
    await _stepLineManager?.setLineCap(LineCap.ROUND);
    await _stepLineManager?.setLineJoin(LineJoin.ROUND);
    _poiMarkerManager = await mapboxMap.annotations
        .createCircleAnnotationManager();
  }

  Future<void> _onMapTap(MapContentGestureContext gestureContext) async {
    final mapboxMap = _mapboxMap;
    if (mapboxMap == null) return;

    // Clear previous selection if any
    context.read<MapBloc>().add(MapSelectLocation(null));

    // 1. Get screen coordinate for querying features
    final screenCoord = await mapboxMap.pixelForCoordinate(
      gestureContext.point,
    );

    final poiFeature = await _queryRenderedFeature(
      mapboxMap,
      screenCoord,
      const ['poi-label', 'transit-label', 'road-label'],
    );

    if (poiFeature != null) {
      final location = _buildLocationFromFeature(
        poiFeature,
        fallbackPoint: gestureContext.point,
      );
      if (location != null && mounted) {
        context.read<MapBloc>().add(MapSelectLocation(location));
      }
      return;
    }

    final placeFeature =
        await _queryRenderedFeature(mapboxMap, screenCoord, const [
          'place-label',
          'locality-label',
          'neighborhood-label',
          'settlement-subdivision-label',
          'hamlet-label',
          'settlement-major-label',
          'settlement-minor-label',
          'natural-point-label',
          'water-point-label',
        ]);

    if (placeFeature != null) {
      final location = _buildLocationFromFeature(
        placeFeature,
        fallbackPoint: gestureContext.point,
      );
      
      final props = placeFeature['properties'] as Map?;
      final type = props?['type'] as String? ?? props?['class'] as String?;
      
      List<String>? geocodeTypes;
      if (type == 'district') {
        geocodeTypes = ['district', 'place', 'region', 'country'];
      } else if (type == 'neighborhood' || type == 'suburb' || type == 'locality') {
        geocodeTypes = ['neighborhood', 'locality', 'district', 'place', 'region', 'country'];
      } else if (type == 'settlement' || type == 'city' || type == 'place') {
        geocodeTypes = ['place', 'region', 'country'];
      }

      if (location != null && mounted) {
        context.read<MapBloc>().add(
          MapSelectLocation(
            location, 
            preferReverseGeocode: true,
            reverseGeocodeTypes: geocodeTypes,
          ),
        );
      }
      return;
    }
  }

  Future<void> _onMapLongTap(MapContentGestureContext gestureContext) async {
    // 1. Select the point and use reverse geocoding for label
    if (mounted) {
      context.read<MapBloc>().add(
        MapSelectLocation(
          LocationEntity(
            point: gestureContext.point,
            label: LocationEntity.selectedLocationLabel,
          ),
          preferReverseGeocode: true,
        ),
      );
    }
  }

  Future<Map<String, dynamic>?> _queryRenderedFeature(
    MapboxMap mapboxMap,
    ScreenCoordinate screenCoord,
    List<String> layerIds,
  ) async {
    final features = await mapboxMap.queryRenderedFeatures(
      RenderedQueryGeometry.fromScreenCoordinate(screenCoord),
      RenderedQueryOptions(layerIds: layerIds),
    );
    if (features.isEmpty) return null;
    final dynamic queriedRenderedFeature = features.first;
    final Map? feature =
        queriedRenderedFeature?.queriedFeature?.feature as Map?;
    if (feature == null) return null;
    return feature.cast<String, dynamic>();
  }

  LocationEntity? _buildLocationFromFeature(
    Map<String, dynamic> feature, {
    required Point fallbackPoint,
  }) {
    final properties = feature['properties'] as Map?;
    final geometry = feature['geometry'] as Map?;
    final coordinates = geometry?['coordinates'] as List?;

    Point point = fallbackPoint;
    if (coordinates != null && coordinates.length >= 2) {
      final lng = (coordinates[0] as num).toDouble();
      final lat = (coordinates[1] as num).toDouble();
      point = Point(coordinates: Position(lng, lat));
    }

    final label =
        _firstNonEmptyProperty(properties, const [
          'name',
          'name_tr',
          'name:tr',
          'name_en',
        ]) ??
        LocationEntity.selectedLocationLabel;

    final subtitle = _buildSubtitle(properties, label);
    final context = _buildContext(properties, label);
    final country = _firstNonEmptyProperty(properties, const [
      'country',
      'country_name',
    ]);

    return LocationEntity(
      point: point,
      label: label,
      placeName: label,
      subtitle: subtitle,
      country: country,
      context: context,
    );
  }

  String? _firstNonEmptyProperty(Map? props, List<String> keys) {
    if (props == null) return null;
    for (final key in keys) {
      final value = props[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return null;
  }

  String? _buildSubtitle(Map? props, String label) {
    final parts = _buildContext(props, label);
    if (parts == null || parts.isEmpty) return null;
    return parts.join(', ');
  }

  List<String>? _buildContext(Map? props, String label) {
    if (props == null) return null;
    final parts = <String>[];

    // Mapbox label features often have 'type' or 'class' property
    final type = props['type'] as String? ?? props['class'] as String?;

    bool canIncludeNeighborhood = true;
    bool canIncludeDistrict = true;
    bool canIncludePlace = true;
    bool canIncludeRegion = true;

    if (type == 'district') {
      // If it's a district, we only want the city (place)
      canIncludeNeighborhood = false;
      canIncludeDistrict = false;
    } else if (type == 'neighborhood' || type == 'suburb' || type == 'locality') {
      // If it's a neighborhood, we want district and city
      canIncludeNeighborhood = false;
    }

    void add(String key, bool allowed) {
      if (!allowed) return;
      final value = props[key];
      if (value is String && value.trim().isNotEmpty) {
        final trimmed = value.trim();
        // Don't add if it matches the label or already in parts
        if (trimmed.toLowerCase() != label.toLowerCase() &&
            !parts.contains(trimmed)) {
          parts.add(trimmed);
        }
      }
    }

    add('neighborhood', canIncludeNeighborhood);
    add('locality', canIncludeNeighborhood);
    add('district', canIncludeDistrict);
    add('place', canIncludePlace);

    // If it's a place label feature (district/neighborhood), we usually want to be concise.
    // If we found a city (place), we can skip region/country based on user's "sadece" request.
    final hasPlace = parts.any((p) => p.isNotEmpty); // Simple check if we added anything yet
    final isGeneralPlace = type != null && (type == 'district' || type == 'neighborhood' || type == 'suburb' || type == 'locality');

    add('region', canIncludeRegion && (!isGeneralPlace || !hasPlace));
    add('country', !isGeneralPlace || !hasPlace);
    
    return parts.isEmpty ? null : parts;
  }

  Future<void> _updateMarkers(Point? start, Point? end) async {
    final manager = _markerManager;
    if (manager == null) return;

    try {
      if (_startMarker != null) {
        await manager.delete(_startMarker!);
      }
    } catch (e) {
      debugPrint("Error deleting start marker: $e");
    } finally {
      _startMarker = null;
    }

    try {
      if (_endMarker != null) {
        await manager.delete(_endMarker!);
      }
    } catch (e) {
      debugPrint("Error deleting end marker: $e");
    } finally {
      _endMarker = null;
    }

    if (start != null) {
      try {
        _startMarker = await manager.create(
          CircleAnnotationOptions(
            geometry: start,
            circleColor: Colors.green.toARGB32(),
            circleRadius: 6,
            circleStrokeColor: Colors.white.toARGB32(),
            circleStrokeWidth: 2,
          ),
        );
      } catch (e) {
        debugPrint("Error creating start marker: $e");
      }
    }

    if (end != null) {
      try {
        _endMarker = await manager.create(
          CircleAnnotationOptions(
            geometry: end,
            circleColor: Colors.redAccent.toARGB32(),
            circleRadius: 6,
            circleStrokeColor: Colors.white.toARGB32(),
            circleStrokeWidth: 2,
          ),
        );
      } catch (e) {
        debugPrint("Error creating end marker: $e");
      }
    }
  }

  Future<void> _renderRoutes(
    List<RouteEntity> routes,
    int selectedIndex,
  ) async {
    final manager = _routeLineManager;
    if (manager == null) return;

    try {
      if (_routeLines.isNotEmpty) {
        await manager.deleteAll();
      }
    } catch (e) {
      debugPrint("Error clearing route lines: $e");
    } finally {
      _routeLines = [];
    }

    if (routes.isEmpty) return;

    final options = <PolylineAnnotationOptions>[];
    for (var i = 0; i < routes.length; i++) {
      final route = routes[i];
      final isSelected = i == selectedIndex;

      options.addAll(
        _buildRoutePolylineOptions(
          route,
          routeIndex: i,
          isSelected: isSelected,
        ),
      );
    }

    final created = await manager.createMulti(options);
    _routeLines = created.whereType<PolylineAnnotation>().toList();
  }

  List<PolylineAnnotationOptions> _buildRoutePolylineOptions(
    RouteEntity route, {
    required int routeIndex,
    required bool isSelected,
  }) {
    if (!isSelected) {
      return [
        _simpleRouteLine(
          route,
          routeIndex: routeIndex,
          isSelected: false,
          color: const Color(0xFF7A7A7A),
        ),
      ];
    }

    final congestion = route.congestion;
    final coords = route.geometry.coordinates;
    if (congestion == null || congestion.isEmpty || coords.length < 2) {
      return [
        _simpleRouteLine(
          route,
          routeIndex: routeIndex,
          isSelected: true,
          color: const Color(0xFF2E7DFF),
        ),
      ];
    }

    final segments = <PolylineAnnotationOptions>[];
    final points = <Point>[];
    String current = _congestionForIndex(0, congestion);
    points.add(Point(coordinates: coords[0]));

    for (var i = 0; i < coords.length - 1; i++) {
      final nextPoint = Point(coordinates: coords[i + 1]);
      final level = _congestionForIndex(i, congestion);
      if (level != current && points.length > 1) {
        segments.add(_segmentLine(points, routeIndex, current));
        points.clear();
        points.add(Point(coordinates: coords[i]));
        current = level;
      }
      points.add(nextPoint);
    }

    if (points.length > 1) {
      segments.add(_segmentLine(points, routeIndex, current));
    }

    return segments;
  }

  PolylineAnnotationOptions _simpleRouteLine(
    RouteEntity route, {
    required int routeIndex,
    required bool isSelected,
    required Color color,
  }) {
    return PolylineAnnotationOptions(
      geometry: route.geometry,
      lineColor: color.toARGB32(),
      lineWidth: isSelected ? 6.0 : 4.0,
      lineOpacity: isSelected ? 0.9 : 0.6,
      lineSortKey: isSelected ? 2 : 1,
      customData: <String, Object>{'routeIndex': routeIndex},
    );
  }

  PolylineAnnotationOptions _segmentLine(
    List<Point> points,
    int routeIndex,
    String congestionLevel,
  ) {
    return PolylineAnnotationOptions(
      geometry: LineString.fromPoints(points: List<Point>.from(points)),
      lineColor: _congestionColor(congestionLevel).toARGB32(),
      lineWidth: 6.0,
      lineOpacity: 0.95,
      lineSortKey: 3,
      customData: <String, Object>{'routeIndex': routeIndex},
    );
  }

  String _congestionForIndex(int index, List<String> congestion) {
    if (index < 0) return 'unknown';
    if (index >= congestion.length) {
      return congestion.isNotEmpty ? congestion.last : 'unknown';
    }
    return congestion[index];
  }

  Color _congestionColor(String level) {
    switch (level.trim().toLowerCase()) {
      case 'low':
        return const Color(0xFF2E7D32);
      case 'moderate':
        return const Color(0xFFF9A825);
      case 'heavy':
        return const Color(0xFFE65100);
      case 'severe':
        return const Color(0xFFB71C1C);
      default:
        return const Color(0xFF2E7DFF);
    }
  }

  String _routeSignature(RouteEntity route) {
    final coords = route.geometry.coordinates;
    if (coords.isEmpty) {
      return '${route.distanceMeters.toStringAsFixed(1)}_${route.durationSeconds}';
    }

    final first = coords.first;
    final last = coords.last;
    return '${coords.length}_${route.distanceMeters.toStringAsFixed(1)}_${route.durationSeconds}_${first.lng.toStringAsFixed(4)}_${first.lat.toStringAsFixed(4)}_${last.lng.toStringAsFixed(4)}_${last.lat.toStringAsFixed(4)}';
  }

  Future<void> _fitCameraToRoute(RouteEntity route) async {
    final mapboxMap = _mapboxMap;
    if (mapboxMap == null) return;

    final points = route.geometry.coordinates
        .map((pos) => Point(coordinates: pos))
        .toList();
    if (points.isEmpty) return;

    final camera = await mapboxMap.cameraForCoordinatesPadding(
      points,
      CameraOptions(bearing: 0, pitch: 0),
      MbxEdgeInsets(top: 180, left: 40, bottom: 200, right: 40),
      _maxZoomLevel,
      null,
    );
    await mapboxMap.setCamera(camera);
  }

  Future<void> _renderStepHighlight(RouteEntity? route, int? stepIndex) async {
    final manager = _stepLineManager;
    if (manager == null) return;

    try {
      if (_stepLines.isNotEmpty) {
        await manager.deleteAll();
      }
    } catch (e) {
      debugPrint('Error clearing step line: $e');
    } finally {
      _stepLines = [];
    }

    if (route == null || stepIndex == null) return;
    if (stepIndex < 0 || stepIndex >= route.steps.length) return;
    final step = route.steps[stepIndex];
    final geometry = step.geometry;
    if (geometry == null) return;

    final options = PolylineAnnotationOptions(
      geometry: geometry,
      lineColor: const Color(0xFFFFC107).toARGB32(),
      lineWidth: 8.0,
      lineOpacity: 0.95,
      lineSortKey: 4,
    );

    final created = await manager.create(options);
    _stepLines = [created];
  }

  void _scheduleRoutePoiScan(RouteEntity route) {
    _poiScanTimer?.cancel();
    _poiScanTimer = Timer(const Duration(milliseconds: 900), () {
      _collectRoutePois(route);
    });
  }

  Future<void> _collectRoutePois(RouteEntity route) async {
    if (_poiScanInFlight) return;
    final mapboxMap = _mapboxMap;
    if (mapboxMap == null) return;

    final coords = route.geometry.coordinates;
    if (coords.length < 2) return;

    final signature =
        '${coords.length}-${route.distanceMeters.toStringAsFixed(1)}';
    if (_lastPoiSignature == signature) return;
    _lastPoiSignature = signature;

    _poiScanInFlight = true;
    try {
      final poiSet = <String>{};
      final poiList = <LocationEntity>[];
      final sampleTarget = 30;
      final stride = (coords.length / sampleTarget).ceil().clamp(
        1,
        coords.length,
      );

      for (var i = 0; i < coords.length; i += stride) {
        final point = Point(coordinates: coords[i]);
        final screen = await mapboxMap.pixelForCoordinate(point);
        final features = await mapboxMap.queryRenderedFeatures(
          RenderedQueryGeometry.fromScreenCoordinate(screen),
          RenderedQueryOptions(
            layerIds: [
              'poi-label',
              'transit-label',
              'road-label',
              'natural-point-label',
              'water-point-label',
            ],
          ),
        );

        for (final item in features) {
          final queriedFeature = item?.queriedFeature;
          final Map? feature = queriedFeature?.feature as Map?;
          final Map? properties = feature?['properties'] as Map?;
          final String? label = properties?['name'] as String?;
          final Map? geometry = feature?['geometry'] as Map?;
          final List? coordinates = geometry?['coordinates'] as List?;
          if (label == null || coordinates == null || coordinates.length < 2) {
            continue;
          }
          final lng = (coordinates[0] as num).toDouble();
          final lat = (coordinates[1] as num).toDouble();
          final key =
              '${label.toLowerCase()}_${lng.toStringAsFixed(4)}_${lat.toStringAsFixed(4)}';
          if (poiSet.contains(key)) continue;
          poiSet.add(key);
          poiList.add(
            LocationEntity(
              point: Point(coordinates: Position(lng, lat)),
              label: label,
            ),
          );
          if (poiList.length >= 12) break;
        }

        if (poiList.length >= 12) break;
      }

      if (mounted) {
        context.read<MapBloc>().add(MapRoutePoisUpdated(poiList));
      }
    } catch (e) {
      debugPrint('Route POI scan error: $e');
    } finally {
      _poiScanInFlight = false;
    }
  }

  Future<void> _updatePoiMarkers(
    List<LocationEntity> pois, {
    int? selectedIndex,
  }) async {
    final manager = _poiMarkerManager;
    if (manager == null) return;

    try {
      if (_poiMarkers.isNotEmpty) {
        await manager.deleteAll();
      }
    } catch (e) {
      debugPrint('Error clearing POI markers: $e');
    } finally {
      _poiMarkers = [];
    }

    if (pois.isEmpty) return;
    final options = <CircleAnnotationOptions>[];
    for (var i = 0; i < pois.length; i++) {
      final poi = pois[i];
      final isSelected = selectedIndex != null && selectedIndex == i;
      options.add(
        CircleAnnotationOptions(
          geometry: poi.point,
          circleColor: isSelected
              ? const Color(0xFF2E7DFF).toARGB32()
              : const Color(0xFFFFC107).toARGB32(),
          circleRadius: isSelected ? 7 : 5,
          circleStrokeColor: isSelected
              ? Colors.white.toARGB32()
              : Colors.black.toARGB32(),
          circleStrokeWidth: isSelected ? 1.6 : 1.2,
        ),
      );
    }
    final created = await manager.createMulti(options);
    _poiMarkers = created.whereType<CircleAnnotation>().toList();
  }

  Future<void> _focusOnPoi(LocationEntity poi) async {
    final mapboxMap = _mapboxMap;
    if (mapboxMap == null) return;
    try {
      await mapboxMap.setCamera(CameraOptions(center: poi.point, zoom: 15.0));
    } catch (e) {
      debugPrint('POI focus error: $e');
    }
  }

  void _scheduleRouteCache(RouteEntity route) {
    _cacheTimer?.cancel();
    _cacheTimer = Timer(_cacheDebounce, () => _cacheRouteRegion(route));
  }

  Future<void> _cacheRouteRegion(RouteEntity route) async {
    if (_cacheInFlight) return;
    final mapboxMap = _mapboxMap;
    final tileStore = _tileStore;
    if (mapboxMap == null || tileStore == null) return;

    final points = route.geometry.coordinates
        .map((pos) => Point(coordinates: pos))
        .toList();
    if (points.isEmpty) return;

    _cacheInFlight = true;
    try {
      final camera = await mapboxMap.cameraForCoordinatesPadding(
        points,
        CameraOptions(bearing: 0, pitch: 0),
        MbxEdgeInsets(top: 180, left: 40, bottom: 200, right: 40),
        _maxZoomLevel,
        null,
      );
      final bounds = await mapboxMap.coordinateBoundsForCamera(camera);
      if (bounds.infiniteBounds) return;

      final geometry = _boundsToPolygon(bounds);
      final zoom = camera.zoom ?? _maxZoomLevel;
      final int minZoom = (zoom - 2).floor().clamp(0, 14).toInt();
      final int maxZoom = (zoom + 1).ceil().clamp(minZoom + 1, 16).toInt();
      final regionId =
          '$_routeRegionPrefix${_tileRegionIdFor(bounds, minZoom, maxZoom)}';
      if (regionId == _lastTileRegionId) return;
      if (await _tileRegionExists(tileStore, regionId)) {
        _lastTileRegionId = regionId;
        await _clearOldCache(tileStore, keepRegionId: regionId);
        return;
      }

      final options = TileRegionLoadOptions(
        geometry: geometry.toJson().cast<String?, Object?>(),
        descriptorsOptions: [
          TilesetDescriptorOptions(
            styleURI: _styleUri,
            minZoom: minZoom,
            maxZoom: maxZoom,
            pixelRatio: 1.0,
          ),
        ],
        metadata: <String?, Object?>{
          'regionId': regionId,
          'minZoom': minZoom,
          'maxZoom': maxZoom,
          'kind': 'route',
        },
        acceptExpired: true,
        networkRestriction: NetworkRestriction.NONE,
      );

      await tileStore.loadTileRegion(regionId, options, null);
      _lastTileRegionId = regionId;
      await _clearOldCache(tileStore, keepRegionId: regionId);
    } catch (e) {
      debugPrint('Route cache error: $e');
    } finally {
      _cacheInFlight = false;
    }
  }

  Future<void> _clearOldCache(
    TileStore tileStore, {
    String? keepRegionId,
  }) async {
    try {
      final regions = await tileStore.allTileRegions();
      for (final region in regions) {
        final id = region.id;
        if (!id.startsWith(_routeRegionPrefix)) continue;
        if (keepRegionId != null && id == keepRegionId) continue;
        try {
          await tileStore.removeRegion(id);
        } catch (e) {
          debugPrint('Failed to remove tile region $id: $e');
        }
      }
      if (keepRegionId == null) {
        _lastTileRegionId = null;
      }
    } catch (e) {
      debugPrint('Tile cache cleanup failed: $e');
    }
  }

  Future<bool> _tileRegionExists(TileStore tileStore, String id) async {
    try {
      await tileStore.tileRegion(id);
      return true;
    } catch (_) {
      return false;
    }
  }

  String _tileRegionIdFor(CoordinateBounds bounds, int minZoom, int maxZoom) {
    double q(num v) => (v * 1000).roundToDouble() / 1000;
    final sw = bounds.southwest.coordinates;
    final ne = bounds.northeast.coordinates;
    return 'z$minZoom-$maxZoom'
        '_${q(sw.lat)}_${q(sw.lng)}_${q(ne.lat)}_${q(ne.lng)}';
  }

  Polygon _boundsToPolygon(CoordinateBounds bounds) {
    final sw = bounds.southwest.coordinates;
    final ne = bounds.northeast.coordinates;
    final west = sw.lng.toDouble();
    final south = sw.lat.toDouble();
    final east = ne.lng.toDouble();
    final north = ne.lat.toDouble();

    return Polygon.fromPoints(
      points: [
        [
          Point(coordinates: Position(west, south)),
          Point(coordinates: Position(east, south)),
          Point(coordinates: Position(east, north)),
          Point(coordinates: Position(west, north)),
          Point(coordinates: Position(west, south)),
        ],
      ],
    );
  }

  Future<void> _determinePosition() async {
    _isLoadingLocation.value = true;
    final l10n = AppLocalizations.of(context)!;
    try {
      bool serviceEnabled = await geo.Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        _showSnackBar(l10n.map_location_services_disabled);
        return;
      }

      geo.LocationPermission permission =
          await geo.Geolocator.checkPermission();
      if (permission == geo.LocationPermission.denied) {
        permission = await geo.Geolocator.requestPermission();
        if (permission == geo.LocationPermission.denied) {
          if (!mounted) return;
          _showSnackBar(l10n.map_location_permission_denied);
          return;
        }
      }

      final position = await geo.Geolocator.getCurrentPosition();
      if (!mounted) return;
      final center = Point(
        coordinates: Position(position.longitude, position.latitude),
      );
      await _mapboxMap?.setCamera(CameraOptions(center: center, zoom: 15.0));
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(l10n.map_location_error);
    } finally {
      _isLoadingLocation.value = false;
    }
  }

  Future<void> _resetMapBearing() async {
    final mapboxMap = _mapboxMap;
    if (mapboxMap == null) return;
    try {
      await mapboxMap.setCamera(CameraOptions(bearing: 0));
    } catch (e) {
      debugPrint('Compass reset error: $e');
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  void _onLayersPressed() {
    _showSnackBar(AppLocalizations.of(context)!.map_layers_coming_soon);
  }

  @override
  Widget build(BuildContext context) {
    return _buildScaffold(context);
  }

  Widget _buildScaffold(BuildContext context) {
    final theme = Theme.of(context);
    final topSafe = MediaQuery.viewPaddingOf(context).top;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: BlocListener<MapBloc, MapState>(
        listenWhen: (previous, current) =>
            previous.status != current.status ||
            previous.startPoint != current.startPoint ||
            previous.endPoint != current.endPoint ||
            previous.routeOptions != current.routeOptions ||
            previous.selectedRouteIndex != current.selectedRouteIndex ||
            previous.selectedStepIndex != current.selectedStepIndex ||
            previous.routePois != current.routePois ||
            previous.selectedPoiIndex != current.selectedPoiIndex,
        listener: (context, state) {
          if (state.status == MapStatus.error && state.error != null) {
            _showSnackBar(state.error!);
          }

          _updateMarkers(state.startPoint?.point, state.endPoint?.point);
          _renderRoutes(state.routeOptions, state.selectedRouteIndex);

          if (state.routeOptions.isNotEmpty) {
            final activeRoute = state.routeOptions[state.selectedRouteIndex];
            final activeRouteKey = _routeSignature(activeRoute);
            final routeChanged = _lastActiveRouteKey != activeRouteKey;

            if (routeChanged) {
              _lastActiveRouteKey = activeRouteKey;
              _fitCameraToRoute(activeRoute);
              _scheduleRouteCache(activeRoute);
              _scheduleRoutePoiScan(activeRoute);
            }

            _renderStepHighlight(activeRoute, state.selectedStepIndex);
          } else {
            final tileStore = _tileStore;
            if (tileStore != null) {
              unawaited(_clearOldCache(tileStore));
            }
            _renderStepHighlight(null, null);
            _lastPoiSignature = null;
            _lastActiveRouteKey = null;
          }

          _updatePoiMarkers(
            state.routePois,
            selectedIndex: state.selectedPoiIndex,
          );

          if (state.selectedPoiIndex != null &&
              state.selectedPoiIndex! >= 0 &&
              state.selectedPoiIndex! < state.routePois.length) {
            _focusOnPoi(state.routePois[state.selectedPoiIndex!]);
          }
        },
        child: Stack(
          children: [
            Positioned.fill(
              child: MapWidget(
                key: const ValueKey('mapWidget'),
                styleUri: _styleUri,
                androidHostingMode: AndroidPlatformViewHostingMode.TLHC_VD,
                cameraOptions:
                    _lastCamera ??
                    CameraOptions(center: _defaultCenter, zoom: 12.0),
                onMapCreated: _onMapCreated,
                onMapLoadedListener: _onMapLoaded,
                onCameraChangeListener: _onCameraChanged,
                onMapIdleListener: _onMapIdle,
                onTapListener: _onMapTap,
                onLongTapListener: _onMapLongTap,
              ),
            ),

            Positioned(
              right: _fabRightPadding,
              top: topSafe + 12 + 46 + 8 + 46 + 16,
              child: _buildMapControls(theme),
            ),

            Positioned(
              left: 16,
              right: 16,
              top: 0,
              child: SafeArea(
                child: Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: MapSearchBar(),
                ),
              ),
            ),

            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: MediaQuery.removeViewInsets(
                context: context,
                removeBottom: true,
                child: RoutePoiPanel(
                  bottomBarHeight: _getBottomBarHeight(context),
                ),
              ),
            ),

            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: MediaQuery.removeViewInsets(
                context: context,
                removeBottom: true,
                child: MapBottomSheet(
                  forceCollapsed: false,
                  bottomBarHeight: _getBottomBarHeight(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapControls(ThemeData theme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (AppFeatureFlags.showMapLayers) ...[
          FloatingActionButton(
            heroTag: 'mapLayersFab',
            mini: true,
            elevation: 6,
            backgroundColor: theme.colorScheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            onPressed: _onLayersPressed,
            child: Icon(
              Icons.layers_outlined,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: _fabSpacing),
        ],
        ValueListenableBuilder<bool>(
          valueListenable: _isLoadingLocation,
          builder: (context, isLoading, child) {
            return FloatingActionButton(
              heroTag: 'mapLocationFab',
              mini: true,
              elevation: 8,
              backgroundColor: theme.colorScheme.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              onPressed: isLoading ? null : _determinePosition,
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : const Icon(Icons.my_location, color: Colors.white),
            );
          },
        ),
        const SizedBox(height: _fabSpacing),
        FloatingActionButton(
          heroTag: 'mapCompassFab',
          mini: true,
          elevation: 6,
          backgroundColor: theme.colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          onPressed: _resetMapBearing,
          child: Transform.rotate(
            angle: _compassRotation,
            child: Icon(
              Icons.explore_rounded,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }

  double _getBottomBarHeight(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    final double scale = (size.width / 390).clamp(0.85, 1.2);
    return (10.0 * scale) + (bottomPadding > 0 ? bottomPadding : 15.0);
  }
}
