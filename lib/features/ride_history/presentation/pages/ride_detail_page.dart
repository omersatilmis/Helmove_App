import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:helmove/core/theme/app_colors.dart';
import 'package:helmove/core/theme/text_styles.dart';
import 'package:helmove/core/widgets/app_frosted_button.dart';
import 'package:helmove/features/ride_history/domain/entities/ride_entity.dart';
import 'package:intl/intl.dart';

class RideDetailPage extends StatelessWidget {
  final RideEntity ride;
  const RideDetailPage({super.key, required this.ride});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          _MapSliver(ride: ride),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _TitleRow(ride: ride),
                  const SizedBox(height: 24),
                  _StatsGrid(ride: ride),
                  const SizedBox(height: 24),
                  _PointsInfo(ride: ride),
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
  const _MapSliver({required this.ride});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
        background: ride.points.isEmpty
            ? _MapPlaceholder()
            : _RouteMapView(points: ride.points),
      ),
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

class _RouteMapView extends StatelessWidget {
  final List<RidePoint> points;
  const _RouteMapView({required this.points});

  @override
  Widget build(BuildContext context) {
    // TODO: MapboxMap widget ile polyline çiz
    // Şu an placeholder — backend bağlandıktan sonra implement edilecek
    return CustomPaint(
      painter: _RoutePainter(points: points),
      child: Container(
        color: const Color(0xFF1a1a2e),
      ),
    );
  }
}

class _RoutePainter extends CustomPainter {
  final List<RidePoint> points;
  const _RoutePainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    final lats = points.map((p) => p.latitude).toList();
    final lngs = points.map((p) => p.longitude).toList();
    final minLat = lats.reduce((a, b) => a < b ? a : b);
    final maxLat = lats.reduce((a, b) => a > b ? a : b);
    final minLng = lngs.reduce((a, b) => a < b ? a : b);
    final maxLng = lngs.reduce((a, b) => a > b ? a : b);

    final latRange = (maxLat - minLat).abs();
    final lngRange = (maxLng - minLng).abs();

    double toX(double lng) => latRange < 1e-9
        ? size.width / 2
        : ((lng - minLng) / lngRange) * size.width * 0.8 + size.width * 0.1;

    double toY(double lat) => lngRange < 1e-9
        ? size.height / 2
        : (1 - (lat - minLat) / latRange) * size.height * 0.8 +
              size.height * 0.1;

    final path = Path();
    path.moveTo(toX(points.first.longitude), toY(points.first.latitude));
    for (final p in points.skip(1)) {
      path.lineTo(toX(p.longitude), toY(p.latitude));
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF6dd5ed)
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // Başlangıç noktası
    canvas.drawCircle(
      Offset(toX(points.first.longitude), toY(points.first.latitude)),
      6,
      Paint()..color = Colors.green,
    );
    // Bitiş noktası
    canvas.drawCircle(
      Offset(toX(points.last.longitude), toY(points.last.latitude)),
      6,
      Paint()..color = Colors.red,
    );
  }

  @override
  bool shouldRepaint(_RoutePainter old) => old.points != points;
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
    ).format(ride.startedAt);

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
            style: AppTextStyles.bodyMedium.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
