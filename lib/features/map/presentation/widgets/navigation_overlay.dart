import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:helmove/l10n/app_localizations.dart';

import '../providers/map_bloc.dart';
import '../providers/map_event.dart';

class NavigationTopHud extends StatelessWidget {
  const NavigationTopHud({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MapBloc, MapState>(
      buildWhen: (p, c) =>
          p.isNavigating != c.isNavigating ||
          p.selectedStepIndex != c.selectedStepIndex ||
          p.routeOptions != c.routeOptions,
      builder: (context, state) {
        if (!state.isNavigating || state.routeOptions.isEmpty) {
          return const SizedBox.shrink();
        }

        final route = state.routeOptions[state.selectedRouteIndex];
        final steps = route.steps;
        final idx = state.selectedStepIndex ?? 0;
        final step = idx < steps.length ? steps[idx] : null;
        final nextStep = (idx + 1) < steps.length ? steps[idx + 1] : null;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A2E).withValues(alpha: 0.82),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Row(
                    children: [
                      _ManeuverIcon(
                        type: step?.maneuverType,
                        modifier: step?.maneuverModifier,
                        size: 44,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              step?.instruction ?? 'Rotaya devam edin',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                height: 1.2,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (step?.name != null && step!.name!.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                step.name!,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.6),
                                  fontSize: 13,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (step != null) ...[
                        const SizedBox(width: 12),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              _formatDist(step.distanceMeters),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                height: 1.0,
                              ),
                            ),
                            if (nextStep != null)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _ManeuverIcon(
                                    type: nextStep.maneuverType,
                                    modifier: nextStep.maneuverModifier,
                                    size: 16,
                                    color: Colors.white54,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _formatDist(nextStep.distanceMeters),
                                    style: const TextStyle(
                                      color: Colors.white54,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  static String _formatDist(double meters) {
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
    return '${meters.toInt()} m';
  }
}

class NavigationBottomHud extends StatelessWidget {
  final double? currentSpeedKmh;
  final double bottomBarHeight;

  const NavigationBottomHud({
    super.key,
    this.currentSpeedKmh,
    required this.bottomBarHeight,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MapBloc, MapState>(
      buildWhen: (p, c) =>
          p.isNavigating != c.isNavigating ||
          p.routeOptions != c.routeOptions ||
          p.selectedRouteIndex != c.selectedRouteIndex ||
          p.selectedStepIndex != c.selectedStepIndex,
      builder: (context, state) {
        if (!state.isNavigating) return const SizedBox.shrink();

        final l10n = AppLocalizations.of(context)!;
        double remainingKm = 0;
        int remainingSec = 0;

        if (state.routeOptions.isNotEmpty) {
          final route = state.routeOptions[state.selectedRouteIndex];
          final passedSteps = state.selectedStepIndex ?? 0;
          remainingKm = route.distanceMeters / 1000;
          remainingSec = route.durationSeconds.toInt();
          // Subtract passed steps
          for (int i = 0; i < passedSteps && i < route.steps.length; i++) {
            remainingKm -= route.steps[i].distanceMeters / 1000;
            remainingSec -= route.steps[i].durationSeconds.toInt();
          }
          if (remainingKm < 0) remainingKm = 0;
          if (remainingSec < 0) remainingSec = 0;
        }

        final eta = DateTime.now().add(Duration(seconds: remainingSec));
        final etaStr =
            '${eta.hour.toString().padLeft(2, '0')}:${eta.minute.toString().padLeft(2, '0')}';

        final speed = currentSpeedKmh ?? 0;

        return Padding(
          padding: EdgeInsets.only(bottom: bottomBarHeight),
          child: ClipRRect(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A2E).withValues(alpha: 0.88),
                  border: Border(
                    top: BorderSide(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
                child: Row(
                  children: [
                    // Speed
                    _InfoPill(
                      top: speed.toStringAsFixed(0),
                      bottom: 'km/s',
                      icon: Icons.speed,
                    ),
                    const SizedBox(width: 16),
                    // Remaining distance
                    _InfoPill(
                      top: remainingKm >= 1
                          ? remainingKm.toStringAsFixed(1)
                          : (remainingKm * 1000).toInt().toString(),
                      bottom: remainingKm >= 1 ? 'km' : 'm',
                      icon: Icons.route,
                    ),
                    const SizedBox(width: 16),
                    // ETA
                    _InfoPill(
                      top: etaStr,
                      bottom: 'tahmini',
                      icon: Icons.schedule,
                    ),
                    const Spacer(),
                    // Stop button
                    ElevatedButton.icon(
                      onPressed: () =>
                          context.read<MapBloc>().add(MapStopNavigationPressed()),
                      icon: const Icon(Icons.stop_circle_outlined, size: 20),
                      label: Text(l10n.map_stop_navigation),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD32F2F),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _InfoPill extends StatelessWidget {
  final String top;
  final String bottom;
  final IconData icon;

  const _InfoPill(
      {required this.top, required this.bottom, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.white54),
        const SizedBox(width: 4),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              top,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                height: 1.0,
              ),
            ),
            Text(
              bottom,
              style: const TextStyle(color: Colors.white54, fontSize: 11),
            ),
          ],
        ),
      ],
    );
  }
}

class _ManeuverIcon extends StatelessWidget {
  final String? type;
  final String? modifier;
  final double size;
  final Color? color;

  const _ManeuverIcon({
    this.type,
    this.modifier,
    this.size = 40,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = color ?? Colors.white;
    final data = _iconFor(type, modifier);
    return Transform(
      alignment: Alignment.center,
      transform: _rotationFor(type, modifier),
      child: Icon(data, color: iconColor, size: size),
    );
  }

  static IconData _iconFor(String? type, String? modifier) {
    final t = type?.toLowerCase() ?? '';
    final m = modifier?.toLowerCase() ?? '';

    if (t == 'arrive') return Icons.location_on;
    if (t == 'depart') return Icons.navigation;
    if (t == 'roundabout' || t == 'rotary') {
      return m.contains('left') ? Icons.roundabout_left : Icons.roundabout_right;
    }
    if (t == 'turn' || t == 'on ramp' || t == 'off ramp' || t == 'fork') {
      if (m.contains('uturn')) {
        return m.contains('left') ? Icons.u_turn_left : Icons.u_turn_right;
      }
      if (m.contains('sharp left') || m.contains('left')) return Icons.turn_left;
      if (m.contains('sharp right') || m.contains('right')) return Icons.turn_right;
      return Icons.straight;
    }
    if (t == 'continue' || t == 'new name' || t == 'merge') {
      if (m.contains('left')) return Icons.turn_slight_left;
      if (m.contains('right')) return Icons.turn_slight_right;
    }
    return Icons.straight;
  }

  static Matrix4 _rotationFor(String? type, String? modifier) {
    final t = type?.toLowerCase() ?? '';
    if (t == 'depart') {
      return Matrix4.rotationZ(0);
    }
    return Matrix4.identity();
  }
}
