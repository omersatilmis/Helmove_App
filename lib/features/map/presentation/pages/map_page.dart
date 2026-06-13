import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:shared_preferences/shared_preferences.dart';
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
import '../widgets/navigation_overlay.dart';
import '../../../ride_history/domain/entities/ride_entity.dart';
import '../../../ride_history/domain/repositories/ride_repository.dart';
import '../../../ride_history/domain/services/ride_recording_service.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/utils/polyline_codec.dart';
import '../../../group_ride/presentation/live_ride/live_ride_controller.dart';
import '../../../group_ride/presentation/live_ride/rider_marker_factory.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  // Motosiklet navigasyonu için optimize Mapbox stilleri: yüksek kontrast,
  // az POI. Gündüz = day, gece = night.
  static const String _dayStyleUri = 'mapbox://styles/mapbox/navigation-day-v1';
  static const String _nightStyleUri =
      'mapbox://styles/mapbox/navigation-night-v1';
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
  PolylineAnnotationManager? _routeLineManager;
  PolylineAnnotationManager? _stepLineManager;
  List<PolylineAnnotation> _stepLines = [];
  CircleAnnotationManager? _poiMarkerManager;
  List<CircleAnnotation> _poiMarkers = [];
  // Async render race guard — en son rota render çağrısı kazanır.
  int _routeRenderGen = 0;
  int _markerRenderGen = 0;
  Timer? _poiScanTimer;
  bool _poiScanInFlight = false;
  String? _lastPoiSignature;
  StreamSubscription<Uri>? _deepLinkSub;

  // Navigation / ride recording
  PolylineAnnotationManager? _trailLineManager;
  PolylineAnnotation? _trailAnnotation;
  StreamSubscription<RidePoint>? _recordingSub;
  final List<Point> _trailPoints = [];
  double? _currentSpeedKmh;

  // Live ride (grup canlı konum + ortak rota)
  late final LiveRideController _liveRide = sl<LiveRideController>();
  PointAnnotationManager? _riderAvatarManager;
  PointAnnotationManager? _riderArrowManager;
  PolylineAnnotationManager? _sharedRouteManager;
  final Map<int, PointAnnotation> _riderAvatarAnn = {};
  final Map<int, PointAnnotation> _riderArrowAnn = {};
  PolylineAnnotation? _sharedRouteAnn;
  String? _lastSharedRouteGeometry;
  Uint8List? _arrowBitmapMember;
  Uint8List? _arrowBitmapOrganizer;
  bool _liveRenderInFlight = false;
  bool _liveRenderQueued = false;
  // Avatar/ok bitmap'leri dpr 3'te üretilir; harita üzerinde logical boyut.
  static const double _riderIconSize = 1 / 3.0;
  static const double _riderArrowOrbit = 30.0; // px, avatar çevresi

  // Default Center: Istanbul / Turkey (longitude, latitude)
  final Point _defaultCenter = Point(coordinates: Position(28.9784, 41.0082));
  bool _didInitialGpsCenter = false;
  bool _initialCameraReady = false;
  CameraOptions? _initialCamera;

  // Tema-bağımlı harita stili (gündüz/gece). App temasını takip eder.
  late final ThemeProvider _themeProvider = sl<ThemeProvider>();
  late final String _initialStyleUri;
  String? _currentStyleUri;
  bool _styleInitialized = false;

  static const _prefsLastLat = 'map.last_camera.lat';
  static const _prefsLastLng = 'map.last_camera.lng';
  static const _prefsLastZoom = 'map.last_camera.zoom';

  bool _isDarkMode() {
    final mode = _themeProvider.themeMode;
    if (mode == ThemeMode.dark) return true;
    if (mode == ThemeMode.light) return false;
    // system: platform brightness
    final brightness =
        WidgetsBinding.instance.platformDispatcher.platformBrightness;
    return brightness == Brightness.dark;
  }

  String _resolveStyleUri() =>
      _isDarkMode() ? _nightStyleUri : _dayStyleUri;

  @override
  void initState() {
    super.initState();
    final token = MapboxConfig.accessToken;
    if (token.isEmpty) {
      debugPrint('Mapbox access token is missing.');
    }
    MapboxOptions.setAccessToken(token);
    MapboxMapsOptions.setTileStoreUsageMode(TileStoreUsageMode.READ_AND_UPDATE);
    _currentStyleUri = _resolveStyleUri();
    _initialStyleUri = _currentStyleUri!;
    _themeProvider.addListener(_onThemeChanged);
    _initTileStore();
    _initStylePack();
    _attachDeepLinkListener();
    unawaited(_resolveInitialCamera());
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkRideRecovery());
    _liveRide.addListener(_onLiveRideChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // system temasında cihaz gündüz/gece değişince MediaQuery güncellenir.
    _maybeUpdateMapStyle();
  }

  void _onThemeChanged() => _maybeUpdateMapStyle();

  void _maybeUpdateMapStyle() {
    if (!mounted) return;
    final resolved = _resolveStyleUri();
    if (resolved != _currentStyleUri) {
      _currentStyleUri = resolved;
      // MapWidget.styleUri reactive değil — stili manuel reload et.
      unawaited(_mapboxMap?.loadStyleURI(resolved) ?? Future.value());
      setState(() {}); // FAB ikonu (gündüz/gece) güncellensin
    }
  }

  Future<void> _resolveInitialCamera() async {
    CameraOptions? camera;

    try {
      final prefs = await SharedPreferences.getInstance();
      final lat = prefs.getDouble(_prefsLastLat);
      final lng = prefs.getDouble(_prefsLastLng);
      final zoom = prefs.getDouble(_prefsLastZoom);
      if (lat != null && lng != null) {
        camera = CameraOptions(
          center: Point(coordinates: Position(lng, lat)),
          zoom: zoom ?? 15.0,
        );
      }
    } catch (_) {}

    if (camera == null) {
      try {
        final last = await geo.Geolocator.getLastKnownPosition();
        if (last != null) {
          camera = CameraOptions(
            center: Point(
              coordinates: Position(last.longitude, last.latitude),
            ),
            zoom: 15.0,
          );
        }
      } catch (_) {}
    }

    if (!mounted) return;
    setState(() {
      _initialCamera =
          camera ?? CameraOptions(center: _defaultCenter, zoom: 12.0);
      _initialCameraReady = true;
      // If we restored a real position, skip the post-load GPS jump.
      if (camera != null) _didInitialGpsCenter = true;
    });
  }

  Future<void> _persistLastCamera(CameraState state) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(
        _prefsLastLat,
        state.center.coordinates.lat.toDouble(),
      );
      await prefs.setDouble(
        _prefsLastLng,
        state.center.coordinates.lng.toDouble(),
      );
      await prefs.setDouble(_prefsLastZoom, state.zoom);
    } catch (_) {}
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
    final styleUri = _currentStyleUri ?? _resolveStyleUri();
    try {
      await _offlineManager?.stylePack(styleUri);
    } catch (_) {
      final options = StylePackLoadOptions(
        glyphsRasterizationMode:
            GlyphsRasterizationMode.IDEOGRAPHS_RASTERIZED_LOCALLY,
        acceptExpired: true,
      );
      await _offlineManager?.loadStylePack(styleUri, options, null);
    }
  }

  @override
  void dispose() {
    _themeProvider.removeListener(_onThemeChanged);
    _cacheTimer?.cancel();
    _poiScanTimer?.cancel();
    _isLoadingLocation.dispose();
    _deepLinkSub?.cancel();
    _recordingSub?.cancel();
    _liveRide.removeListener(_onLiveRideChanged);
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
    unawaited(_setupMotorcyclePuck());
    if (!_didInitialGpsCenter) {
      _didInitialGpsCenter = true;
      unawaited(_centerOnCurrentLocationSilently());
    }
  }

  // Stil her yüklendiğinde tetiklenir. İlk yüklemeyi onMapCreated/onMapLoaded
  // hallediyor; sonraki yüklemeler (gündüz/gece geçişi) annotation manager'ları
  // ve puck'ı sıfırlar — bu yüzden yeniden kurup mevcut rotayı tekrar çiziyoruz.
  Future<void> _onStyleLoaded(StyleLoadedEventData _) async {
    if (!_styleInitialized) {
      _styleInitialized = true;
      return;
    }
    await _initAnnotationManagers();
    await _disable3dBuildings();
    await _setupMotorcyclePuck();
    _renderCurrentState();
  }

  void _renderCurrentState() {
    if (!mounted) return;
    final state = context.read<MapBloc>().state;
    _updateMarkers(state.startPoint?.point, state.endPoint?.point);
    _renderRoutes(state.routeOptions, state.selectedRouteIndex);
    if (state.routeOptions.isNotEmpty) {
      _renderStepHighlight(
        state.routeOptions[state.selectedRouteIndex],
        state.selectedStepIndex,
      );
    }
    _updatePoiMarkers(state.routePois, selectedIndex: state.selectedPoiIndex);
    _scheduleLiveRideRender();
  }

  // ── Live ride (grup canlı konum + ortak rota) ─────────────────────────────

  void _onLiveRideChanged() {
    if (!mounted) return;
    _scheduleLiveRideRender();
    setState(() {}); // overlay (sürücü sayısı, paylaşım toggle) tazelensin
  }

  /// Eşzamanlı render'ları serileştirir: bir render sürerken gelen istekler
  /// tek bir kuyruğa düşer (annotation manager'larda yarış olmasın).
  void _scheduleLiveRideRender() {
    if (_liveRenderInFlight) {
      _liveRenderQueued = true;
      return;
    }
    _liveRenderInFlight = true;
    unawaited(() async {
      try {
        await _renderLiveRide();
      } finally {
        _liveRenderInFlight = false;
        if (_liveRenderQueued) {
          _liveRenderQueued = false;
          _scheduleLiveRideRender();
        }
      }
    }());
  }

  Future<void> _renderLiveRide() async {
    await _renderSharedRoute();
    await _renderRiders();
  }

  Future<void> _renderSharedRoute() async {
    final manager = _sharedRouteManager;
    if (manager == null) return;

    final route = _liveRide.sharedRoute;
    final geometry = route?.geometry;
    final hasRoute = _liveRide.isActive && geometry != null && geometry.isNotEmpty;

    if (!hasRoute) {
      if (_sharedRouteAnn != null || _lastSharedRouteGeometry != null) {
        await manager.deleteAll();
        _sharedRouteAnn = null;
        _lastSharedRouteGeometry = null;
      }
      return;
    }

    if (geometry == _lastSharedRouteGeometry && _sharedRouteAnn != null) {
      return; // değişmedi
    }

    final points = PolylineCodec.decode(geometry);
    await manager.deleteAll();
    _sharedRouteAnn = null;
    if (points.length < 2) {
      _lastSharedRouteGeometry = null;
      return;
    }

    // Ortak rota rengi: kendi rota çizgimizden farklı (mor), gece/gündüz görünür.
    _sharedRouteAnn = await manager.create(
      PolylineAnnotationOptions(
        geometry: LineString(coordinates: points.map((p) => p.coordinates).toList()),
        lineColor: const Color(0xFF7C4DFF).value,
        lineWidth: 6.0,
        lineOpacity: 0.9,
      ),
    );
    _lastSharedRouteGeometry = geometry;
  }

  Future<void> _renderRiders() async {
    final avatarManager = _riderAvatarManager;
    final arrowManager = _riderArrowManager;
    if (avatarManager == null || arrowManager == null) return;

    if (!_liveRide.isActive) {
      if (_riderAvatarAnn.isNotEmpty || _riderArrowAnn.isNotEmpty) {
        await avatarManager.deleteAll();
        await arrowManager.deleteAll();
        _riderAvatarAnn.clear();
        _riderArrowAnn.clear();
      }
      return;
    }

    final riders = _liveRide.riders;
    final activeIds = riders.map((r) => r.userId).toSet();

    // Ayrılan sürücülerin marker'larını sil.
    final removed = _riderAvatarAnn.keys
        .where((id) => !activeIds.contains(id))
        .toList();
    for (final id in removed) {
      final avatar = _riderAvatarAnn.remove(id);
      if (avatar != null) await avatarManager.delete(avatar);
      final arrow = _riderArrowAnn.remove(id);
      if (arrow != null) await arrowManager.delete(arrow);
    }

    for (final rider in riders) {
      final point = Point(coordinates: Position(rider.lng, rider.lat));
      final headingDeg = rider.heading ?? 0.0;
      final offset = _arrowOffsetFor(headingDeg);

      final existingAvatar = _riderAvatarAnn[rider.userId];
      if (existingAvatar != null) {
        existingAvatar.geometry = point;
        await avatarManager.update(existingAvatar);
        final existingArrow = _riderArrowAnn[rider.userId];
        if (existingArrow != null) {
          existingArrow.geometry = point;
          existingArrow.iconRotate = headingDeg;
          existingArrow.iconOffset = offset;
          await arrowManager.update(existingArrow);
        }
        continue;
      }

      // Yeni sürücü — avatar + ok oluştur.
      final ringColor = rider.isOrganizer
          ? const Color(0xFFFFB300)
          : const Color(0xFF2962FF);
      final avatarBytes = await RiderMarkerFactory.buildAvatar(
        userId: rider.userId,
        photoUrl: rider.profilePictureUrl,
        displayName: rider.displayName,
        ringColor: ringColor,
      );
      if (!mounted || !_liveRide.isActive) return;

      final arrowBytes = await _arrowBitmapFor(rider.isOrganizer);
      if (!mounted || !_liveRide.isActive) return;

      final arrow = await arrowManager.create(
        PointAnnotationOptions(
          geometry: point,
          image: arrowBytes,
          iconSize: _riderIconSize,
          iconRotate: headingDeg,
          iconOffset: offset,
        ),
      );
      _riderArrowAnn[rider.userId] = arrow;

      final avatar = await avatarManager.create(
        PointAnnotationOptions(
          geometry: point,
          image: avatarBytes,
          iconSize: _riderIconSize,
          textField: rider.displayName,
          textOffset: [0.0, 1.6],
          textSize: 12.0,
          textColor: Colors.white.value,
          textHaloColor: Colors.black.value,
          textHaloWidth: 1.4,
          textAnchor: TextAnchor.TOP,
        ),
      );
      _riderAvatarAnn[rider.userId] = avatar;
    }
  }

  /// Heading yönünde avatar çevresine ok yerleştirmek için piksel offset.
  /// Heading 0 = kuzey (yukarı). iconOffset y ekseni aşağı pozitif.
  List<double> _arrowOffsetFor(double headingDeg) {
    final rad = headingDeg * math.pi / 180.0;
    final x = _riderArrowOrbit * math.sin(rad);
    final y = -_riderArrowOrbit * math.cos(rad);
    return [x, y];
  }

  Future<Uint8List> _arrowBitmapFor(bool isOrganizer) async {
    if (isOrganizer) {
      return _arrowBitmapOrganizer ??=
          await RiderMarkerFactory.buildArrow(color: const Color(0xFFFFB300));
    }
    return _arrowBitmapMember ??=
        await RiderMarkerFactory.buildArrow(color: const Color(0xFF2962FF));
  }

  Future<void> _centerOnCurrentLocationSilently() async {
    try {
      if (!await geo.Geolocator.isLocationServiceEnabled()) return;
      var permission = await geo.Geolocator.checkPermission();
      if (permission == geo.LocationPermission.denied) {
        permission = await geo.Geolocator.requestPermission();
      }
      if (permission == geo.LocationPermission.denied ||
          permission == geo.LocationPermission.deniedForever) {
        return;
      }
      final position = await geo.Geolocator.getCurrentPosition();
      if (!mounted) return;
      final center = Point(
        coordinates: Position(position.longitude, position.latitude),
      );
      await _mapboxMap?.setCamera(CameraOptions(center: center, zoom: 15.0));
    } catch (_) {}
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
    unawaited(_persistLastCamera(cameraState));
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
    _trailLineManager = await mapboxMap.annotations
        .createPolylineAnnotationManager();
    await _trailLineManager?.setLineCap(LineCap.ROUND);
    await _trailLineManager?.setLineJoin(LineJoin.ROUND);
    // Ortak rota (grup) — kendi rota çizgimizin üstünde, ayrı renk.
    _sharedRouteManager = await mapboxMap.annotations
        .createPolylineAnnotationManager();
    await _sharedRouteManager?.setLineCap(LineCap.ROUND);
    await _sharedRouteManager?.setLineJoin(LineJoin.ROUND);
    _poiMarkerManager = await mapboxMap.annotations
        .createCircleAnnotationManager();
    // Diğer sürücüler: önce oklar (alt katman), sonra avatarlar (üst katman).
    _riderArrowManager = await mapboxMap.annotations
        .createPointAnnotationManager();
    // Ok, harita ile hizalı dönsün (harita döndüğünde yön doğru kalsın).
    await _riderArrowManager?.setIconRotationAlignment(
      IconRotationAlignment.MAP,
    );
    _riderAvatarManager = await mapboxMap.annotations
        .createPointAnnotationManager();
    // Stil reload sonrası eski annotation referansları geçersiz — sıfırla.
    _riderAvatarAnn.clear();
    _riderArrowAnn.clear();
    _sharedRouteAnn = null;
    _lastSharedRouteGeometry = null;
    // Harita zaten aktif bir grup sürüşüyle açıldıysa canlı katmanı çiz.
    if (_liveRide.isActive) _scheduleLiveRideRender();
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

    // Race guard: ardışık çağrılar üst üste bindiğinde (yeni rota seçimi
    // birden fazla state emit ediyor) geç biten eski çağrının marker'ı geri
    // bırakmasını engelle — en son çağrı kazanır (bkz. _renderRoutes).
    final gen = ++_markerRenderGen;

    // Tekil delete yerine deleteAll: yarış anında referansı kaybolan eski
    // bitiş noktaları da temizlensin (bu manager yalnızca bitiş marker'ını
    // tutuyor).
    try {
      await manager.deleteAll();
    } catch (e) {
      debugPrint("Error deleting markers: $e");
    }

    if (gen != _markerRenderGen) return; // daha yeni bir çağrı devraldı

    // Başlangıç (yeşil) marker'ı çizilmiyor — kullanıcının konumu zaten motor
    // puck'ı ile gösteriliyor; başlangıç noktasında ayrıca nokta gerekmez.

    if (end != null) {
      try {
        final created = await manager.create(
          CircleAnnotationOptions(
            geometry: end,
            circleColor: Colors.redAccent.toARGB32(),
            circleRadius: 6,
            circleStrokeColor: Colors.white.toARGB32(),
            circleStrokeWidth: 2,
          ),
        );
        if (gen != _markerRenderGen) {
          // Biz create beklerken yeni çağrı geldi — bu marker artık bayat.
          try {
            await manager.delete(created);
          } catch (_) {}
        }
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

    // Race guard: clear + yeni rota hızlı ardışık gelince, geç biten eski
    // render'ın eski rotayı geri çizmesini engelle. En son çağrı kazanır.
    final gen = ++_routeRenderGen;

    try {
      await manager.deleteAll();
    } catch (e) {
      debugPrint("Error clearing route lines: $e");
    }

    if (gen != _routeRenderGen || routes.isEmpty) return;

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

    await manager.createMulti(options);
    // Bu render tamamlanırken yeni bir render başladıysa, çizdiklerimizi geri al.
    if (gen != _routeRenderGen) {
      try {
        await manager.deleteAll();
      } catch (_) {}
    }
  }

  static const _routeSelectedColor = Color(0xFF00B4FF);
  // Alternatif (seçili olmayan) rota tema-bağımlı: gecede açık gri-mavi
  // (koyu harita üzerinde görünür), gündüzde koyu gri.
  Color get _routeUnselectedColor =>
      _isDarkMode() ? const Color(0xFFAAB8CC) : const Color(0xFF556677);
  // Casing (rota kenarlığı) tema-bağımlı: gündüzde beyaz, gecede koyu —
  // böylece rota çizgisi haritanın yeşil/açık yollarından her zaman ayrışır.
  Color get _routeCasingColor =>
      _isDarkMode() ? const Color(0xFF002B55) : Colors.white;

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
          color: _routeUnselectedColor,
        ),
      ];
    }

    // Casing (rota altındaki kenarlık) — kontrast için. Tema-bağımlı renk,
    // tam opak ve geniş ki rota her zemin üzerinde net ayrışsın.
    final casingOpt = PolylineAnnotationOptions(
      geometry: route.geometry,
      lineColor: _routeCasingColor.toARGB32(),
      lineWidth: 11.0,
      lineOpacity: 0.95,
      lineSortKey: 0,
      customData: <String, Object>{'routeIndex': routeIndex},
    );

    final congestion = route.congestion;
    final coords = route.geometry.coordinates;
    if (congestion == null || congestion.isEmpty || coords.length < 2) {
      return [
        casingOpt,
        _simpleRouteLine(
          route,
          routeIndex: routeIndex,
          isSelected: true,
          color: _routeSelectedColor,
        ),
      ];
    }

    final segments = <PolylineAnnotationOptions>[casingOpt];
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
            styleURI: _currentStyleUri ?? _resolveStyleUri(),
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

  // ── Motorcycle puck ─────────────────────────────────────────────────────────

  /// Kullanıcının konum puck'ı için motor görseli. Asset varsa onu (tasarım
  /// görseli) kullanır; yoksa Material `two_wheeler` glyph'ine düşer.
  /// Görsel yukarı (kuzey) bakmalı — Mapbox heading'e göre döndürür.
  static const String _motorPuckAsset = 'assets/icons/ic_motor_puck.png';

  Future<void> _setupMotorcyclePuck() async {
    final mapboxMap = _mapboxMap;
    if (mapboxMap == null) return;
    try {
      final puckBytes = await _loadPuckBytes();
      if (puckBytes == null) return;
      // Şeffaf topImage → Mapbox'ın varsayılan mavi noktasını gizler.
      final transparent = await _transparentPng();

      await mapboxMap.location.updateSettings(
        LocationComponentSettings(
          enabled: true,
          pulsingEnabled: false,
          showAccuracyRing: false,
          // Cihaz pusulası ile motor ikonu telefonun baktığı yöne döner.
          puckBearingEnabled: true,
          puckBearing: PuckBearing.HEADING,
          locationPuck: LocationPuck(
            locationPuck2D: LocationPuck2D(
              // bearingImage → heading'e göre döner; topImage şeffaf → mavi nokta yok.
              bearingImage: puckBytes,
              topImage: transparent,
            ),
          ),
        ),
      );
    } catch (e) {
      debugPrint('Motorcycle puck error: $e');
    }
  }

  // Puck görselinin en uzun kenarı bu piksele küçültülür (kaynak ne olursa olsun
  // orantılı kalır). Çok büyük/küçük gelirse bu değeri değiştir.
  static const int _puckTargetPx = 120;

  Future<Uint8List?> _loadPuckBytes() async {
    // 1) Asset (varsa) — tasarım motor görseli (PNG, şeffaf, yukarı bakan).
    try {
      final data = await rootBundle.load(_motorPuckAsset);
      final raw = data.buffer.asUint8List();
      return await _resizePng(raw, _puckTargetPx);
    } catch (_) {
      // Asset henüz eklenmemiş — glyph fallback'e düş.
    }
    // 2) Fallback: Material two_wheeler glyph'ini PNG bitmap'e çiz.
    try {
      const size = 72.0;
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder, const Rect.fromLTWH(0, 0, size, size));
      final textPainter = TextPainter(textDirection: ui.TextDirection.ltr)
        ..text = TextSpan(
          text: String.fromCharCode(Icons.two_wheeler.codePoint),
          style: TextStyle(
            inherit: false,
            color: const Color(0xFF1565C0),
            fontSize: size * 0.85,
            fontFamily: Icons.two_wheeler.fontFamily,
          ),
        )
        ..layout();
      textPainter.paint(
        canvas,
        Offset((size - textPainter.width) / 2, (size - textPainter.height) / 2),
      );
      final picture = recorder.endRecording();
      final image = await picture.toImage(size.toInt(), size.toInt());
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('Puck glyph fallback error: $e');
      return null;
    }
  }

  /// Tamamen şeffaf küçük PNG — varsayılan puck noktasını gizlemek için.
  Future<Uint8List> _transparentPng() async {
    final recorder = ui.PictureRecorder();
    ui.Canvas(recorder, const Rect.fromLTWH(0, 0, 4, 4));
    final picture = recorder.endRecording();
    final image = await picture.toImage(4, 4);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return byteData!.buffer.asUint8List();
  }

  /// PNG byte'larını en uzun kenar [maxSide] olacak şekilde orantılı küçültür.
  Future<Uint8List> _resizePng(Uint8List src, int maxSide) async {
    final codec = await ui.instantiateImageCodec(src);
    final frame = await codec.getNextFrame();
    final image = frame.image;
    final w = image.width;
    final h = image.height;
    final longest = w > h ? w : h;
    if (longest <= maxSide) {
      image.dispose();
      return src; // zaten yeterince küçük
    }
    final scale = maxSide / longest;
    final targetW = (w * scale).round();
    final targetH = (h * scale).round();
    image.dispose();

    final scaledCodec = await ui.instantiateImageCodec(
      src,
      targetWidth: targetW,
      targetHeight: targetH,
    );
    final scaledFrame = await scaledCodec.getNextFrame();
    final scaledImage = scaledFrame.image;
    final byteData = await scaledImage.toByteData(
      format: ui.ImageByteFormat.png,
    );
    scaledImage.dispose();
    return byteData?.buffer.asUint8List() ?? src;
  }

  // ── Navigation / Recording ──────────────────────────────────────────────────

  void _startRecordingSubscription(MapBloc bloc) {
    if (_recordingSub != null) return;
    _trailPoints.clear();
    // Navigasyon başlar başlamaz haritayı kullanıcının konumuna kilitle —
    // ilk GPS noktası gelene kadar beklemeden hemen yakınlaş + eğ.
    unawaited(_lockCameraToCurrentLocation());
    _recordingSub = bloc.recordingStream.listen((point) {
      if (!mounted) return;
      final mapPoint = Point(
        coordinates: Position(point.longitude, point.latitude),
      );
      _trailPoints.add(mapPoint);
      _updateTrailPolyline();
      _followCamera(mapPoint);
      _tryAdvanceStep(bloc, mapPoint);
      setState(() {
        _currentSpeedKmh = point.speedKmh;
      });
    });
  }

  void _tryAdvanceStep(MapBloc bloc, Point userPoint) {
    final state = bloc.state;
    if (!state.isNavigating || state.routeOptions.isEmpty) return;
    final route = state.routeOptions[state.selectedRouteIndex];
    final stepIdx = state.selectedStepIndex ?? 0;
    if (stepIdx >= route.steps.length - 1) return;

    final currentStep = route.steps[stepIdx];
    final maneuver = currentStep.maneuverLocation;
    if (maneuver == null) return;

    final dist = _haversinePoints(userPoint, maneuver);
    if (dist < 40) {
      bloc.add(MapRouteStepSelected(stepIdx + 1));
    }
  }

  double _haversinePoints(Point a, Point b) {
    const r = 6371000.0;
    final lat1 = (a.coordinates.lat ?? 0) * math.pi / 180;
    final lat2 = (b.coordinates.lat ?? 0) * math.pi / 180;
    final dLat = ((b.coordinates.lat ?? 0) - (a.coordinates.lat ?? 0)) * math.pi / 180;
    final dLon = ((b.coordinates.lng ?? 0) - (a.coordinates.lng ?? 0)) * math.pi / 180;
    final sinDLat = math.sin(dLat / 2);
    final sinDLon = math.sin(dLon / 2);
    final h = sinDLat * sinDLat + math.cos(lat1) * math.cos(lat2) * sinDLon * sinDLon;
    return 2 * r * math.asin(math.sqrt(h));
  }

  double? _computeBearing() {
    if (_trailPoints.length < 2) return null;
    final prev = _trailPoints[_trailPoints.length - 2].coordinates;
    final curr = _trailPoints.last.coordinates;
    final dLon = ((curr.lng ?? 0) - (prev.lng ?? 0)) * math.pi / 180;
    final lat1 = (prev.lat ?? 0) * math.pi / 180;
    final lat2 = (curr.lat ?? 0) * math.pi / 180;
    final y = math.sin(dLon) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);
    final bearing = math.atan2(y, x) * 180 / math.pi;
    return (bearing + 360) % 360;
  }

  void _stopRecordingSubscription() {
    _recordingSub?.cancel();
    _recordingSub = null;
    _trailPoints.clear();
    _clearTrailPolyline();
    if (mounted) setState(() { _currentSpeedKmh = null; });
  }

  Future<void> _lockCameraToCurrentLocation() async {
    final mapboxMap = _mapboxMap;
    if (mapboxMap == null) return;
    try {
      final pos = await geo.Geolocator.getCurrentPosition();
      if (!mounted) return;
      final center = Point(
        coordinates: Position(pos.longitude, pos.latitude),
      );
      await mapboxMap.flyTo(
        CameraOptions(
          center: center,
          zoom: 17.0,
          pitch: 60.0,
          bearing: pos.heading >= 0 ? pos.heading : null,
        ),
        MapAnimationOptions(duration: 1000, startDelay: 0),
      );
    } catch (_) {}
  }

  Future<void> _followCamera(Point center) async {
    final mapboxMap = _mapboxMap;
    if (mapboxMap == null) return;
    try {
      final bearing = _computeBearing();
      await mapboxMap.flyTo(
        CameraOptions(
          center: center,
          zoom: 17.0,
          pitch: 60.0,
          bearing: bearing,
        ),
        MapAnimationOptions(duration: 800, startDelay: 0),
      );
    } catch (_) {}
  }

  Future<void> _updateTrailPolyline() async {
    final manager = _trailLineManager;
    if (manager == null || _trailPoints.length < 2) return;
    try {
      if (_trailAnnotation != null) {
        await manager.delete(_trailAnnotation!);
        _trailAnnotation = null;
      }
      _trailAnnotation = await manager.create(
        PolylineAnnotationOptions(
          geometry: LineString.fromPoints(points: List.from(_trailPoints)),
          lineColor: const Color(0xFFFF6B35).toARGB32(),
          lineWidth: 4.0,
          lineOpacity: 0.9,
          lineSortKey: 5,
        ),
      );
    } catch (_) {}
  }

  Future<void> _clearTrailPolyline() async {
    try {
      await _trailLineManager?.deleteAll();
      _trailAnnotation = null;
    } catch (_) {}
  }

  Widget _buildSpeedBadge(ThemeData theme) {
    final speed = _currentSpeedKmh;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            speed != null ? speed.toStringAsFixed(0) : '0',
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.bold,
              height: 1.0,
            ),
          ),
          Text(
            'km/h',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _checkRideRecovery() async {
    if (!mounted) return;
    final service = sl<RideRecordingService>();
    final recovered = await service.recoverIfNeeded();
    if (!mounted || recovered == null) return;

    final save = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Tamamlanmamış Sürüş'),
        content: Text(
          '${recovered.distanceFormatted} mesafeli tamamlanmamış bir sürüş kaydı bulundu. Kaydetmek ister misiniz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Yoksay'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );

    if (!mounted) return;
    if (save == true) {
      try {
        final repo = sl<RideRepository>();
        await repo.createRide(recovered);
        await service.discardRecovery();
        _showSnackBar('Sürüş kaydedildi.');
      } catch (_) {
        _showSnackBar('Sürüş kaydedilemedi.');
      }
    } else {
      await service.discardRecovery();
    }
  }

  String _resolveMapErrorMessage(String key, AppLocalizations l10n) {
    switch (key) {
      case 'map_error_search_failed':
        return l10n.map_error_search_failed;
      case 'map_error_location_not_found':
        return l10n.map_error_location_not_found;
      case 'map_error_configuration':
        return l10n.map_error_configuration;
      case 'map_error_unauthorized':
        return l10n.map_error_unauthorized;
      case 'map_error_rate_limited':
        return l10n.map_error_rate_limited;
      case 'map_error_network':
        return l10n.map_error_network;
      case 'map_error_invalid_response':
        return l10n.map_error_invalid_response;
      case 'map_error_unknown':
        return l10n.map_error_unknown;
      default:
        return key;
    }
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
      body: BlocConsumer<MapBloc, MapState>(
        listenWhen: (previous, current) =>
            previous.status != current.status ||
            previous.startPoint != current.startPoint ||
            previous.endPoint != current.endPoint ||
            previous.routeOptions != current.routeOptions ||
            previous.selectedRouteIndex != current.selectedRouteIndex ||
            previous.selectedStepIndex != current.selectedStepIndex ||
            previous.routePois != current.routePois ||
            previous.selectedPoiIndex != current.selectedPoiIndex ||
            previous.isNavigating != current.isNavigating ||
            previous.rideSaved != current.rideSaved,
        listener: (context, state) {
          if (state.rideSaved != null) {
            _showSnackBar(
              state.rideSaved! ? 'Sürüş kaydedildi.' : 'Sürüş kaydedilemedi.',
            );
            context.read<MapBloc>().add(MapRideSaveAcknowledged());
          }

          if (state.status == MapStatus.error && state.error != null) {
            final l10n = AppLocalizations.of(context)!;
            _showSnackBar(_resolveMapErrorMessage(state.error!, l10n));
          }

          _updateMarkers(state.startPoint?.point, state.endPoint?.point);
          _renderRoutes(state.routeOptions, state.selectedRouteIndex);

          if (state.routeOptions.isNotEmpty) {
            final activeRoute = state.routeOptions[state.selectedRouteIndex];
            final activeRouteKey = _routeSignature(activeRoute);
            final routeChanged = _lastActiveRouteKey != activeRouteKey;

            if (routeChanged) {
              _lastActiveRouteKey = activeRouteKey;
              if (!state.isNavigating) _fitCameraToRoute(activeRoute);
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

          if (state.isNavigating) {
            _startRecordingSubscription(context.read<MapBloc>());
          } else {
            _stopRecordingSubscription();
          }
        },
        buildWhen: (previous, current) =>
            previous.isNavigating != current.isNavigating,
        builder: (context, state) {
          final isNavigating = state.isNavigating;
          return Stack(
            children: [
              Positioned.fill(
                child: _initialCameraReady
                    ? MapWidget(
                        key: const ValueKey('mapWidget'),
                        styleUri: _initialStyleUri,
                        androidHostingMode:
                            AndroidPlatformViewHostingMode.TLHC_VD,
                        cameraOptions: _lastCamera ?? _initialCamera!,
                        onMapCreated: _onMapCreated,
                        onMapLoadedListener: _onMapLoaded,
                        onStyleLoadedListener: _onStyleLoaded,
                        onCameraChangeListener: _onCameraChanged,
                        onMapIdleListener: _onMapIdle,
                        onTapListener: _onMapTap,
                        onLongTapListener: _onMapLongTap,
                      )
                    : Container(
                        color: const Color(0xFF1A1A1A),
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
              ),

              if (!isNavigating)
                Positioned(
                  right: _fabRightPadding,
                  top: topSafe + 12 + 52 + 16,
                  child: _buildMapControls(theme),
                ),

              if (!isNavigating)
                Positioned(
                  left: 16,
                  right: 16,
                  top: 0,
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: MapSearchBar(),
                    ),
                  ),
                ),

              if (!isNavigating)
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

              if (!isNavigating && _liveRide.isActive)
                Positioned(
                  left: 16,
                  top: topSafe + 12 + 52 + 16,
                  child: _buildLiveRidePanel(theme, context),
                ),

              if (_currentSpeedKmh != null && !isNavigating)
                Positioned(
                  right: _fabRightPadding + 4,
                  bottom: _getBottomBarHeight(context) + 160,
                  child: _buildSpeedBadge(theme),
                ),

              if (!isNavigating)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: MediaQuery.removeViewInsets(
                    context: context,
                    removeBottom: true,
                    child: MapBottomSheet(
                      bottomBarHeight: _getBottomBarHeight(context),
                    ),
                  ),
                ),

              if (isNavigating)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: const NavigationTopHud(),
                ),

              // Discord tarzı "kim konuşuyor" — manevra kartının altında.
              if (isNavigating)
                Positioned(
                  top: MediaQuery.viewPaddingOf(context).top + 100,
                  left: 16,
                  right: 16,
                  child: const NavigationSpeakingIndicator(),
                ),

              if (isNavigating)
                Positioned(
                  right: _fabRightPadding,
                  bottom: MediaQuery.paddingOf(context).bottom + 150,
                  child: _buildRecenterButton(theme),
                ),

              if (isNavigating)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: NavigationBottomHud(
                    currentSpeedKmh: _currentSpeedKmh,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLiveRidePanel(ThemeData theme, BuildContext context) {
    final cs = theme.colorScheme;
    final riderCount = _liveRide.riders.length;
    final sharing = _liveRide.isSharingLocation;
    final showPublish = _liveRide.isOrganizer;

    return Material(
      color: cs.surface.withValues(alpha: 0.92),
      elevation: 6,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.groups_rounded, size: 20, color: cs.primary),
                  const SizedBox(width: 6),
                  Text(
                    '$riderCount',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            // Konum paylaşımı toggle (opt-out)
            IconButton(
              tooltip: sharing ? 'Konum paylaşımı açık' : 'Konum paylaşımı kapalı',
              onPressed: () => _liveRide.setSharing(!sharing),
              icon: Icon(
                sharing
                    ? Icons.location_on_rounded
                    : Icons.location_off_rounded,
                color: sharing ? cs.primary : cs.error,
              ),
            ),
            if (showPublish)
              Padding(
                padding: const EdgeInsets.only(left: 2, right: 4),
                child: TextButton.icon(
                  onPressed: () => _publishRouteToGroup(context),
                  icon: const Icon(Icons.alt_route_rounded, size: 18),
                  label: const Text('Rotayı Paylaş'),
                  style: TextButton.styleFrom(
                    foregroundColor: cs.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _publishRouteToGroup(BuildContext context) async {
    final mapState = context.read<MapBloc>().state;
    if (mapState.routeOptions.isEmpty) {
      _showSnackBar('Önce bir rota oluşturun.');
      return;
    }
    final route = mapState.routeOptions[mapState.selectedRouteIndex];
    final points = route.geometry.coordinates
        .map((p) => Point(coordinates: p))
        .toList();
    if (points.length < 2) {
      _showSnackBar('Rota geçersiz.');
      return;
    }
    final encoded = PolylineCodec.encode(points);
    final ok = await _liveRide.publishRoute(
      geometry: encoded,
      profile: 'driving',
      distanceMeters: route.distanceMeters,
      durationSeconds: route.durationSeconds.round(),
    );
    if (!mounted) return;
    _showSnackBar(ok ? 'Rota gruba gönderildi.' : 'Rota gönderilemedi.');
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
        const SizedBox(height: _fabSpacing),
        FloatingActionButton(
          heroTag: 'mapDayNightFab',
          mini: true,
          elevation: 6,
          backgroundColor: theme.colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          onPressed: _toggleDayNight,
          child: Icon(
            _isDarkMode()
                ? Icons.light_mode_rounded
                : Icons.dark_mode_rounded,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildRecenterButton(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: theme.colorScheme.surface,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => unawaited(_lockCameraToCurrentLocation()),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Icon(
              Icons.my_location_rounded,
              color: theme.colorScheme.primary,
              size: 32,
            ),
          ),
        ),
      ),
    );
  }

  void _toggleDayNight() {
    // Harita + tüm app teması tek kaynaktan (ThemeProvider) yönetilir, böylece
    // her zaman ya tamamen gündüz ya tamamen gece olur.
    _themeProvider.setThemeMode(
      _isDarkMode() ? ThemeMode.light : ThemeMode.dark,
    );
  }

  double _getBottomBarHeight(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    final double scale = (size.width / 390).clamp(0.85, 1.2);
    return (10.0 * scale) + (bottomPadding > 0 ? bottomPadding : 15.0);
  }
}
