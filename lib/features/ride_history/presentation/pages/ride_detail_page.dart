import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:helmove/core/di/injection_container.dart';
import 'package:helmove/core/theme/app_colors.dart';
import 'package:helmove/core/theme/text_styles.dart';
import 'package:helmove/core/widgets/app_frosted_button.dart';
import 'package:helmove/features/map/config/mapbox_config.dart';
import 'package:helmove/features/ride_history/domain/entities/ride_entity.dart';
import 'package:helmove/features/ride_history/domain/repositories/ride_repository.dart';
import 'package:intl/intl.dart';

class RideDetailPage extends StatefulWidget {
  final RideEntity ride;
  const RideDetailPage({super.key, required this.ride});

  @override
  State<RideDetailPage> createState() => _RideDetailPageState();
}

class _RideDetailPageState extends State<RideDetailPage> {
  late RideEntity _ride;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _ride = widget.ride;
    final id = widget.ride.id;
    if (id != null) {
      unawaited(_fetchDetail(id));
    }
  }

  Future<void> _fetchDetail(int id) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final full = await sl<RideRepository>().getRideById(id);
      if (!mounted) return;
      setState(() {
        _ride = full;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          _MapSliver(ride: _ride, loading: _loading),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _TitleRow(ride: _ride),
                  const SizedBox(height: 24),
                  _StatsGrid(ride: _ride),
                  const SizedBox(height: 24),
                  _PointsInfo(ride: _ride),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    _ErrorBanner(
                      message: _error!,
                      onRetry: () =>
                          widget.ride.id != null ? _fetchDetail(widget.ride.id!) : null,
                    ),
                  ],
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MapSliver extends StatelessWidget {
  final RideEntity ride;
  final bool loading;
  const _MapSliver({required this.ride, required this.loading});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasPoints = ride.points.length >= 2;
    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      leading: Padding(
        padding: const EdgeInsets.all(8),
        child: AppFrostedButton(
          icon: Icons.arrow_back_ios_new_rounded,
          onTap: () => context.pop(),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: hasPoints
            ? _RouteMapView(points: ride.points)
            : (loading ? _MapLoading() : _MapPlaceholder()),
      ),
    );
  }
}

class _MapLoading extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      color: theme.colorScheme.surfaceContainerLow,
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}

class _MapPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      color: theme.colorScheme.surfaceContainerLow,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.map_outlined,
            size: 48,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 8),
          Text(
            'Harita verisi yok',
            style: AppTextStyles.bodySmall.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _RouteMapView extends StatefulWidget {
  final List<RidePoint> points;
  const _RouteMapView({required this.points});

  @override
  State<_RouteMapView> createState() => _RouteMapViewState();
}

class _RouteMapViewState extends State<_RouteMapView> {
  static const String _dayStyleUri =
      'mapbox://styles/mapbox/navigation-day-v1';
  static const String _nightStyleUri =
      'mapbox://styles/mapbox/navigation-night-v1';

  String _styleFor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? _nightStyleUri
          : _dayStyleUri;

  MapboxMap? _map;
  PolylineAnnotationManager? _lineManager;
  CircleAnnotationManager? _markerManager;

  CameraOptions get _initialCamera {
    final bounds = _boundsFor(widget.points);
    final centerLng = (bounds.minLng + bounds.maxLng) / 2;
    final centerLat = (bounds.minLat + bounds.maxLat) / 2;
    return CameraOptions(
      center: Point(coordinates: Position(centerLng, centerLat)),
      zoom: 12,
    );
  }

  _LatLngBounds _boundsFor(List<RidePoint> pts) {
    var minLat = pts.first.latitude, maxLat = pts.first.latitude;
    var minLng = pts.first.longitude, maxLng = pts.first.longitude;
    for (final p in pts) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }
    return _LatLngBounds(minLat, minLng, maxLat, maxLng);
  }

  Future<void> _onMapCreated(MapboxMap mapboxMap) async {
    _map = mapboxMap;
    MapboxOptions.setAccessToken(MapboxConfig.accessToken);
    await mapboxMap.scaleBar
        .updateSettings(ScaleBarSettings(enabled: false));
    await mapboxMap.compass.updateSettings(CompassSettings(enabled: false));
    await mapboxMap.attribution
        .updateSettings(AttributionSettings(enabled: false));
    await mapboxMap.logo.updateSettings(LogoSettings(enabled: false));

    _lineManager =
        await mapboxMap.annotations.createPolylineAnnotationManager();
    await _lineManager?.setLineCap(LineCap.ROUND);
    await _lineManager?.setLineJoin(LineJoin.ROUND);
    _markerManager =
        await mapboxMap.annotations.createCircleAnnotationManager();

    await _drawTrail();
    await _fitCamera();
  }

  Future<void> _drawTrail() async {
    final lineManager = _lineManager;
    final markerManager = _markerManager;
    if (lineManager == null || markerManager == null) return;

    final coords = widget.points
        .map((p) => Position(p.longitude, p.latitude))
        .toList(growable: false);
    final geometry = LineString(coordinates: coords);

    await lineManager.create(
      PolylineAnnotationOptions(
        geometry: geometry,
        lineColor: 0xFF6dd5ed,
        lineWidth: 5.0,
        lineOpacity: 0.95,
      ),
    );

    final first = widget.points.first;
    final last = widget.points.last;
    await markerManager.create(
      CircleAnnotationOptions(
        geometry:
            Point(coordinates: Position(first.longitude, first.latitude)),
        circleColor: 0xFF43e97b,
        circleRadius: 8,
        circleStrokeColor: 0xFFFFFFFF,
        circleStrokeWidth: 2,
      ),
    );
    await markerManager.create(
      CircleAnnotationOptions(
        geometry:
            Point(coordinates: Position(last.longitude, last.latitude)),
        circleColor: 0xFFf12711,
        circleRadius: 8,
        circleStrokeColor: 0xFFFFFFFF,
        circleStrokeWidth: 2,
      ),
    );
  }

  Future<void> _fitCamera() async {
    final map = _map;
    if (map == null) return;
    final coords =
        widget.points.map((p) => Point(coordinates: Position(p.longitude, p.latitude))).toList();
    final camera = await map.cameraForCoordinatesPadding(
      coords,
      CameraOptions(bearing: 0, pitch: 0),
      MbxEdgeInsets(top: 40, left: 40, bottom: 40, right: 40),
      null,
      null,
    );
    await map.setCamera(camera);
  }

  @override
  Widget build(BuildContext context) {
    return MapWidget(
      key: const ValueKey('rideDetailMap'),
      styleUri: _styleFor(context),
      cameraOptions: _initialCamera,
      onMapCreated: _onMapCreated,
    );
  }
}

class _LatLngBounds {
  final double minLat, minLng, maxLat, maxLng;
  const _LatLngBounds(this.minLat, this.minLng, this.maxLat, this.maxLng);
}

class _TitleRow extends StatelessWidget {
  final RideEntity ride;
  const _TitleRow({required this.ride});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateLabel = DateFormat(
      'd MMMM yyyy, HH:mm',
      'tr_TR',
    ).format(ride.startedAt.toLocal());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          ride.routeLabel.isNotEmpty ? ride.routeLabel : ride.title,
          style: AppTextStyles.h2.copyWith(
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          dateLabel,
          style: AppTextStyles.bodySmall.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final RideEntity ride;
  const _StatsGrid({required this.ride});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.7,
      children: [
        _StatCard(
          icon: Icons.straighten_rounded,
          label: 'Mesafe',
          value: ride.distanceFormatted,
          color: const Color(0xFF2193b0),
        ),
        _StatCard(
          icon: Icons.timer_outlined,
          label: 'Süre',
          value: ride.durationFormatted,
          color: const Color(0xFF6dd5ed),
        ),
        if (ride.avgSpeedKmh != null)
          _StatCard(
            icon: Icons.speed_rounded,
            label: 'Ort. Hız',
            value: '${ride.avgSpeedKmh!.toStringAsFixed(0)} km/s',
            color: const Color(0xFF43e97b),
          ),
        if (ride.maxSpeedKmh != null)
          _StatCard(
            icon: Icons.bolt_rounded,
            label: 'Maks. Hız',
            value: '${ride.maxSpeedKmh!.toStringAsFixed(0)} km/s',
            color: const Color(0xFFf12711),
          ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 22),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: AppTextStyles.h3.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
              Text(
                label,
                style: AppTextStyles.bodySmall.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PointsInfo extends StatelessWidget {
  final RideEntity ride;
  const _PointsInfo({required this.ride});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (ride.points.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(
            Icons.location_on_outlined,
            color: AppColors.primary,
            size: 22,
          ),
          const SizedBox(width: 12),
          Text(
            '${ride.points.length} GPS noktası kaydedildi',
            style: AppTextStyles.bodyMedium.copyWith
              (color: theme.colorScheme.onSurface),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  const _ErrorBanner({required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: theme.colorScheme.error, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Detay yüklenemedi: $message',
              style: AppTextStyles.bodySmall.copyWith(
                color: theme.colorScheme.onErrorContainer,
              ),
            ),
          ),
          if (onRetry != null)
            TextButton(onPressed: onRetry, child: const Text('Tekrar')),
        ],
      ),
    );
  }
}
