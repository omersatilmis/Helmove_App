import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart' as share_plus;
import 'package:helmove/l10n/app_localizations.dart';

import 'package:helmove/core/theme/text_styles.dart';
import 'package:helmove/core/config/app_feature_flags.dart';
import '../../domain/entities/location_entity.dart';
import '../../domain/entities/route_entity.dart';
import '../../domain/entities/route_step_entity.dart';
import '../../../../core/utils/format_utils.dart';
import '../pages/map_destination_search_page.dart';
import '../providers/map_bloc.dart';
import '../providers/map_event.dart';
import 'alternate_route_card.dart';
import 'poi_business_card.dart';
import '../../../../core/widgets/app_frosted_button.dart';
import '../../../../core/enums/user_tier.dart';
import '../../../../core/enums/app_feature.dart';
import '../../../../core/widgets/feature_guard.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import 'map_bottom_sheet.dart'; // Import to access BottomSheetStateProvider

class MapBottomSheetRoute extends StatefulWidget {
  final List<RouteEntity> routes;
  final int selectedIndex;
  final int? selectedStepIndex;
  final LocationEntity? startPoint;
  final List<LocationEntity> stops;
  final LocationEntity? endPoint;

  /// Grup sürüşü rota planlama modu: navigasyon "Başlat" butonu gizlenir
  /// (rota MapPage'in "Bu rotayı kullan" FAB'ı ile onaylanır).
  final bool planningMode;

  const MapBottomSheetRoute({
    super.key,
    required this.routes,
    required this.selectedIndex,
    this.selectedStepIndex,
    this.startPoint,
    this.stops = const [],
    this.endPoint,
    this.planningMode = false,
  });

  @override
  State<MapBottomSheetRoute> createState() => _MapBottomSheetRouteState();
}

class _MapBottomSheetRouteState extends State<MapBottomSheetRoute> {
  bool _stepsExpanded = false;
  bool _businessExpanded = false;
  int _selectedPoiIndex = 0;

  @override
  void didUpdateWidget(covariant MapBottomSheetRoute oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex) {
      _stepsExpanded = false;
      _businessExpanded = false;
    }
  }

  void _toggleSteps() {
    setState(() {
      _stepsExpanded = !_stepsExpanded;
    });
  }

  void _toggleBusiness() {
    setState(() {
      _businessExpanded = !_businessExpanded;
    });
  }

  String? _buildRouteShareLink() {
    final start = widget.startPoint;
    final end = widget.endPoint;
    if (start == null || end == null) {
      return null;
    }

    final stops = widget.stops
        .map(
          (stop) =>
              '${stop.point.coordinates.lat},${stop.point.coordinates.lng}',
        )
        .join('|');

    final uri = Uri(
      scheme: 'helmove',
      host: 'share',
      path: 'route',
      queryParameters: {
        'startLat': start.point.coordinates.lat.toString(),
        'startLng': start.point.coordinates.lng.toString(),
        'endLat': end.point.coordinates.lat.toString(),
        'endLng': end.point.coordinates.lng.toString(),
        'startLabel': start.label,
        'endLabel': end.label,
        if (stops.isNotEmpty) 'stops': stops,
      },
    );

    return uri.toString();
  }

  void _shareRoute() {
    final link = _buildRouteShareLink();
    if (link == null) {
      return;
    }
    share_plus.SharePlus.instance.share(
      share_plus.ShareParams(uri: Uri.parse(link)),
    );
  }

  void _openOriginSearch(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<MapBloc>(),
          child: const MapDestinationSearchPage(isStart: true),
        ),
      ),
    );
  }

  Widget _buildRouteHeader(BuildContext context, ColorScheme colorScheme) {
    final start = widget.startPoint;
    final end = widget.endPoint;
    if (end == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final lineColor = colorScheme.outlineVariant;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Icon column with vertical connector line
            SizedBox(
              width: 28,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 2),
                  Icon(
                    Icons.circle_outlined,
                    size: 14,
                    color: colorScheme.primary,
                  ),
                  Expanded(
                    child: Center(
                      child: Container(
                        width: 2,
                        color: lineColor,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.flag_outlined,
                    size: 14,
                    color: colorScheme.error,
                  ),
                  const SizedBox(height: 2),
                ],
              ),
            ),
            const SizedBox(width: 6),
            // Labels column
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Origin row (tappable)
                  InkWell(
                    onTap: () => _openOriginSearch(context),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 6,
                        horizontal: 4,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              start?.label ?? 'Mevcut Konumunuz',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurface,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Icon(
                            Icons.edit_outlined,
                            size: 14,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Divider(height: 1, color: lineColor),
                  // Destination row
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 6,
                      horizontal: 4,
                    ),
                    child: Text(
                      end.label,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.routes.isEmpty ||
        widget.selectedIndex < 0 ||
        widget.selectedIndex >= widget.routes.length) {
      return const SizedBox.shrink();
    }

    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final route = widget.routes[widget.selectedIndex];
    final trafficLabel = _trafficLabel(route, l10n);
    final steps = route.steps;
    final canExpandSteps = steps.isNotEmpty;

    final snapIndex = BottomSheetStateProvider.of(context)?.snapIndex ?? 2;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- 0. NEREDEN / NEREYE BAŞLIĞI ---
        _buildRouteHeader(context, colorScheme),

        // --- 1. EN ÜST SAĞ: YUVARLAK İKON BUTONLARI ---
        // Her zaman görünür (Min, Mid, Max)
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              trafficLabel,
              style: AppTextStyles.bodySmall.copyWith(
                color: _getTrafficColor(route, colorScheme),
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            if (AppFeatureFlags.showRouteSettings) ...[
              const SizedBox(width: 8),
              _RouteActionIcon(
                icon: Icons.settings_outlined,
                tooltip: l10n.settings,
                onTap: () {}, // Ayarlar
              ),
            ],
            if (AppFeatureFlags.showSaveRouteButton) ...[
              const SizedBox(width: 8),
              _RouteActionIcon(
                icon: Icons.bookmark_border,
                tooltip: l10n.save,
                onTap: () {}, // Kaydet
              ),
            ],
            const SizedBox(width: 8),
            _RouteActionIcon(
              icon: Icons.share_outlined,
              tooltip: l10n.share,
              onTap: _shareRoute, // Paylaş
            ),
            const SizedBox(width: 8),
            _RouteActionIcon(
              icon: Icons.close_rounded,
              tooltip: l10n.cancel,
              onTap: () => context.read<MapBloc>().add(
                MapClearRoutingRequested(),
              ), // İptal
            ),
          ],
        ),

        const SizedBox(height: 0),

        // --- 2. SÜRE, MESAFE VE ETA ---
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Süre
            Text(
              FormatUtils.formatDuration(route.durationSeconds),
              style: AppTextStyles.h1.copyWith(
                color: _getTrafficColor(route, colorScheme),
                fontSize: 30,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(width: 8),
            // Mesafe
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                '(${FormatUtils.formatDistance(route.distanceMeters)})',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            const Spacer(), // ETA'yı en sağ köşeye iter
            // ETA (Tahmini Varış - Alt alta)
            Padding(
              padding: EdgeInsets.zero,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end, // Sağa dayalı
                children: [
                  Text(
                    l10n.map_eta_label,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
                  Text(
                    FormatUtils.formatEta(route.durationSeconds),
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        // --- 3. ROTA DURAKLARI VE ALTERNATİF ROTALAR ---
        // Mid (1) veya Max (2) durumunda görünür
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: snapIndex >= 1
              ? Column(
                  key: const ValueKey('route_mid_section'),
                  children: [
                    const SizedBox(height: 8),
                    _buildAddressSection(colorScheme),
                    const SizedBox(height: 8),
                    AlternateRouteCards(
                      routes: widget.routes,
                      selectedIndex: widget.selectedIndex,
                      onSelected: (index) => context.read<MapBloc>().add(
                        MapRouteSelectionChanged(index),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                )
              : const SizedBox.shrink(),
        ),

        // --- 4. DETAYLAR (İşletmeler, Adımlar, Aksiyonlar) ---
        // Mid (1) ve Max (2) durumunda görünür + Animasyonlu Geçiş
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.05),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            );
          },
          child: snapIndex >= 1
              ? Column(
                  key: const ValueKey('route_details_section'),
                  children: [
                    if (AppFeatureFlags.showMapBusinesses) ...[
                      _buildBusinessSection(colorScheme, l10n),
                      const SizedBox(height: 8),
                    ],
                    _buildStepsSection(
                      colorScheme,
                      steps,
                      canExpandSteps,
                      l10n,
                    ),
                    const SizedBox(height: 8),
                    _buildActionButtons(colorScheme),
                  ],
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildActionButtons(ColorScheme colorScheme) {
    final isDark = colorScheme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final isNavigating = context.watch<MapBloc>().state.isNavigating;

    return Row(
      children: [
        if (!isNavigating)
        Expanded(
          flex: 1,
          child: AppFrostedTextButton(
            text: l10n.map_add_stop,
            onPressed: () =>
                context.read<MapBloc>().add(MapAddStopViewToggled(true)),
            backgroundColor: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.05),
            textColor: colorScheme.onSurface,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            //height: 48,
            //fontSize: 12,
            //borderRadius: 12,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                l10n.map_add_stop,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodySmall.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w300,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ),
        if (AppFeatureFlags.showSendRouteToGroup) ...[
          const SizedBox(width: 8),
          Expanded(
            flex: 1,
            child: FeatureGuard(
              feature: AppFeature.routeSharing,
              tier:
                  context.watch<AuthProvider>().currentUser?.tier ??
                  UserTier.free,
              onLocked: () => context.push('/plans'),
              child: AppFrostedTextButton(
                text: l10n.map_send_to_group,
                onPressed: () {},
                backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
                textColor: colorScheme.primary,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                //height: 48,
                //fontSize: 12,
                //borderRadius: 12,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    l10n.map_send_to_group,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ] else
          const SizedBox(width: 8),
        if (!widget.planningMode)
        Expanded(
          flex: isNavigating ? 2 : 1,
          child: AppFrostedTextButton(
            text: isNavigating ? l10n.map_stop_navigation : l10n.map_start_navigation,
            onPressed: () {
              if (isNavigating) {
                context.read<MapBloc>().add(MapStopNavigationPressed());
              } else {
                // Navigasyon + rota kaydı tek aksiyon ve herkese açık (free).
                context.read<MapBloc>().add(MapStartNavigationPressed());
              }
            },
            backgroundColor: isNavigating
                ? colorScheme.error
                : colorScheme.primary,
            textColor: colorScheme.onPrimary,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                isNavigating ? l10n.map_stop_navigation : l10n.map_start_navigation,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodySmall.copyWith(
                  color: colorScheme.onPrimary,
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStepsList(BuildContext context, List<RouteStepEntity> steps) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    if (steps.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          l10n.map_no_steps_found,
          style: AppTextStyles.bodySmall.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: steps.length,
      itemBuilder: (context, index) {
        final step = steps[index];
        final isSelected = widget.selectedStepIndex == index;
        final isWarning = _isWarningStep(step);

        final title = step.instruction?.trim().isNotEmpty == true
            ? step.instruction!
            : (step.name?.trim().isNotEmpty == true
                  ? step.name!
                  : l10n.map_step_number(index + 1));

        return InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => context.read<MapBloc>().add(MapRouteStepSelected(index)),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? colorScheme.primaryContainer.withValues(alpha: 0.3)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Navigasyon İkonu (Kutudan çıkarılmış, net ve büyük)
                Icon(
                  _iconForStep(step),
                  size: 28,
                  color: isSelected
                      ? colorScheme.primary
                      : (isWarning ? colorScheme.error : colorScheme.onSurface),
                ),
                const SizedBox(width: 10), // iconlar ve yazılar arası boşluk
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        // talimatlar
                        title,
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: colorScheme.onSurface,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            // mesafe ve zaman formatı
                            '${FormatUtils.formatDistance(step.distanceMeters)} - ${FormatUtils.formatDuration(step.durationSeconds)}',
                            style: AppTextStyles.regular.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                          if (isWarning) ...[
                            const SizedBox(width: 8),
                            Icon(
                              Icons.warning_amber_rounded,
                              size: 14,
                              color: colorScheme.error,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              l10n.map_warning,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: colorScheme.error,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBusinessList(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final items = _mockBusinessesForTab(_selectedPoiIndex);

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = items[index];
        return PoiBusinessCard(
          title: item.title,
          distance: item.distance,
          imageUrl: item.imageUrl,
          duration: item.duration,
          type: _normalizeBusinessType(item.type, l10n),
          rating: item.rating,
          reviewCount: item.reviewCount,
          isOpen: _normalizeOpenLabel(item.isOpen, l10n),
          address: _normalizeAddress(item.address, l10n),
        );
      },
    );
  }

  List<_PoiBusinessMock> _mockBusinessesForTab(int index) {
    switch (index) {
      case 0:
        return const [
          _PoiBusinessMock(
            'Shell',
            '7/24 - 0.8 km',
            '0.8 km',
            duration: '2 dk',
            type: 'Istasyon',
            rating: '4.6',
            reviewCount: '120',
            priceLevel: r'$$',
            isOpen: 'Open',
            address: 'Merkez',
            iconUrl: '',
            imageUrl: '',
          ),
          _PoiBusinessMock(
            'BP',
            'Rota üzeri - 2.1 km',
            '2.1 km',
            duration: '4 dk',
          ),
          _PoiBusinessMock(
            'Opet',
            'İstasyon - 3.5 km',
            '3.5 km',
            duration: '6 dk',
          ),
        ];
      case 1:
        return const [
          _PoiBusinessMock(
            'Mola Noktası',
            'Manzara - 1.4 km',
            '1.4 km',
            duration: '3 dk',
          ),
          _PoiBusinessMock('Kafe', 'Kahve + WC', '1.9 km', duration: '5 dk'),
          _PoiBusinessMock('Park', 'Gölge alan', '2.6 km', duration: '7 dk'),
        ];
      case 2:
        return const [
          _PoiBusinessMock(
            'Lastikçi',
            'Acil servis',
            '1.2 km',
            duration: '4 dk',
          ),
          _PoiBusinessMock(
            'Servis A',
            'Bakım - 2.7 km',
            '2.7 km',
            duration: '6 dk',
          ),
          _PoiBusinessMock(
            'Elektrik',
            'Akü takviyesi',
            '3.8 km',
            duration: '8 dk',
          ),
        ];
      default:
        return const [
          _PoiBusinessMock(
            'Ekipman Dükkanı',
            'Kask / Eldiven',
            '4.5 km',
            duration: '9 dk',
          ),
          _PoiBusinessMock(
            'Outdoor',
            'Mont / Yağmurluk',
            '6.2 km',
            duration: '12 dk',
          ),
        ];
    }
  }

  IconData _iconForStep(RouteStepEntity step) {
    final type = step.maneuverType?.toLowerCase() ?? '';
    final modifier = step.maneuverModifier?.toLowerCase() ?? '';

    // Modern navigasyon ikonları
    if (type == 'depart') return Icons.my_location_rounded;
    if (type == 'arrive') return Icons.location_on_rounded;
    if (type == 'roundabout') return Icons.roundabout_right;
    if (type == 'uturn') return Icons.u_turn_right;

    if (modifier.contains('left')) return Icons.turn_left_rounded;
    if (modifier.contains('right')) return Icons.turn_right_rounded;
    if (modifier.contains('straight')) return Icons.straight_rounded;
    if (modifier.contains('slight right')) {
      return Icons.turn_slight_right_rounded;
    }
    if (modifier.contains('slight left')) return Icons.turn_slight_left_rounded;

    return Icons.straight_rounded;
  }

  bool _isWarningStep(RouteStepEntity step) {
    final type = step.maneuverType?.toLowerCase() ?? '';
    return type == 'roundabout' ||
        type == 'uturn' ||
        type == 'merge' ||
        type == 'fork';
  }

  // --- YARDIMCI METOTLAR ---

  Color _getTrafficColor(RouteEntity route, ColorScheme colorScheme) {
    final level = _worstCongestionScore(route.congestion);
    if (level == 4) return colorScheme.error;
    if (level == 3) return Colors.orange.shade700;
    if (level == 2) return Colors.orange.shade400;
    return Colors.green.shade600;
  }

  String _trafficLabel(RouteEntity route, AppLocalizations l10n) {
    final level = _worstCongestionScore(route.congestion);
    switch (level) {
      case 4:
        return l10n.map_traffic_severe;
      case 3:
        return l10n.map_traffic_heavy;
      case 2:
        return l10n.map_traffic_moderate;
      case 1:
        return l10n.map_traffic_low;
      default:
        return l10n.map_traffic_clear;
    }
  }

  int _worstCongestionScore(List<String>? congestion) {
    if (congestion == null || congestion.isEmpty) return 0;
    var worstScore = 0;
    for (final item in congestion) {
      final score = _congestionScore(item);
      if (score > worstScore) worstScore = score;
    }
    return worstScore;
  }

  int _congestionScore(String value) {
    switch (value.trim().toLowerCase()) {
      case 'severe':
        return 4;
      case 'heavy':
        return 3;
      case 'moderate':
        return 2;
      case 'low':
        return 1;
      default:
        return 0;
    }
  }

  String _normalizeOpenLabel(String value, AppLocalizations l10n) {
    final lower = value.toLowerCase();
    if (lower.contains('open') || lower.contains('açık')) {
      return l10n.map_business_open;
    }
    if (lower.contains('closed') || lower.contains('kapalı')) {
      return l10n.map_business_closed;
    }
    return value;
  }

  String _normalizeBusinessType(String value, AppLocalizations l10n) {
    final lower = value.toLowerCase();
    if (lower.contains('işletme') || lower.contains('isletme')) {
      return l10n.map_business_label;
    }
    return value;
  }

  String _normalizeAddress(String value, AppLocalizations l10n) {
    final lower = value.trim().toLowerCase();
    if (lower == 'bilinmiyor' || lower == 'unknown') {
      return l10n.notAvailable;
    }
    return value;
  }

  Widget _buildAddressSection(ColorScheme colorScheme) {
    final l10n = AppLocalizations.of(context)!;
    // --- UNIFIED POINTS LIST ---
    final List<LocationEntity> allPoints = [];
    if (widget.startPoint != null) allPoints.add(widget.startPoint!);
    allPoints.addAll(widget.stops);
    if (widget.endPoint != null) allPoints.add(widget.endPoint!);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.map_route_stops_title,
                style: AppTextStyles.h3.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              BlocBuilder<MapBloc, MapState>(
                buildWhen: (p, c) =>
                    p.routeNeedsUpdate != c.routeNeedsUpdate ||
                    p.isRouting != c.isRouting,
                builder: (context, state) {
                  final bool isEnabled =
                      state.routeNeedsUpdate && !state.isRouting;
                  final String buttonText = state.isRouting
                      ? l10n.map_route_refreshing
                      : l10n.map_route_refresh;

                  return InkWell(
                    onTap: isEnabled
                        ? () {
                            context.read<MapBloc>().add(MapRouteRequested());
                          }
                        : null,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: Text(
                        buttonText,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: isEnabled
                              ? Colors.orangeAccent
                              : colorScheme.onSurfaceVariant.withValues(
                                  alpha: 0.38,
                                ),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (allPoints.isNotEmpty)
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: allPoints.length,
              proxyDecorator: (child, index, animation) {
                return AnimatedBuilder(
                  animation: animation,
                  builder: (context, child) {
                    final double animValue = Curves.easeInOut.transform(
                      animation.value,
                    );
                    final double elevation = animValue * 4;
                    return Material(
                      elevation: elevation,
                      color: elevation > 0
                          ? colorScheme.surfaceContainerHighest.withValues(
                              alpha: 0.8,
                            )
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      child: child,
                    );
                  },
                  child: child,
                );
              },
              onReorder: (oldIndex, newIndex) {
                context.read<MapBloc>().add(
                  MapStopsReordered(oldIndex: oldIndex, newIndex: newIndex),
                );
              },
              itemBuilder: (context, index) {
                final point = allPoints[index];
                final bool isFirst = index == 0;
                final bool isLast = index == allPoints.length - 1;

                return Column(
                  key: ValueKey('point_${point.label}_$index'),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // 1. Drag Handle
                        ReorderableDragStartListener(
                          index: index,
                          child: Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: Icon(
                              Icons.drag_handle_rounded,
                              size: 20,
                              color: colorScheme.onSurfaceVariant.withValues(
                                alpha: 0.4,
                              ),
                            ),
                          ),
                        ),

                        // 2. Point Icon & Label
                        Expanded(
                          child: Row(
                            children: [
                              Column(
                                children: [
                                  Icon(
                                    isFirst
                                        ? Icons.radio_button_checked
                                        : (isLast
                                              ? Icons.location_on
                                              : Icons.trip_origin_rounded),
                                    size: isLast ? 18 : 16,
                                    color: isLast
                                        ? colorScheme.primary
                                        : (isFirst
                                              ? colorScheme.onSurfaceVariant
                                              : colorScheme.onSurfaceVariant
                                                    .withValues(alpha: 0.7)),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  point.label,
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: colorScheme.onSurface,
                                    fontWeight: isFirst || isLast
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                    fontSize: isFirst || isLast ? 14 : 13,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // Vertical Divider alignment (between icons)
                    if (!isLast)
                      Padding(
                        padding: const EdgeInsets.only(
                          left: 39,
                        ), // Handle(32) + IconCenter(16/2=8) - LineCenter(2/2=1) = 39
                        child: Container(
                          width: 2,
                          height: 20,
                          decoration: BoxDecoration(
                            color: colorScheme.outlineVariant.withValues(
                              alpha: 0.3,
                            ),
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildBusinessSection(ColorScheme colorScheme, AppLocalizations l10n) {
    final poiTabs = _buildPoiTabs(l10n);
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          children: [
            InkWell(
              onTap: _toggleBusiness,
              borderRadius: BorderRadius.circular(12),
              child: Row(
                children: [
                  Text(
                    l10n.map_businesses,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    _businessExpanded ? Icons.expand_less : Icons.expand_more,
                    size: 22,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 32,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: poiTabs.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final item = poiTabs[index];
                  final isSelected = index == _selectedPoiIndex;
                  return ChoiceChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          item.icon,
                          size: 14,
                          color: isSelected
                              ? colorScheme.primary
                              : colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 6),
                        Text(item.label),
                      ],
                    ),
                    selected: isSelected,
                    showCheckmark: false,
                    onSelected: (_) {
                      setState(() => _selectedPoiIndex = index);
                    },
                    labelStyle: AppTextStyles.bodySmall.copyWith(
                      fontSize: 12,
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                    selectedColor: colorScheme.primary.withValues(alpha: 0.1),
                    backgroundColor: colorScheme.surface,
                    side: BorderSide(
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.outlineVariant.withValues(alpha: 0.3),
                      width: isSelected ? 2 : 1,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 0,
                    ),
                    visualDensity: VisualDensity.compact,
                  );
                },
              ),
            ),
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Padding(
                padding: const EdgeInsets.only(top: 10),
                child: _buildBusinessList(context),
              ),
              crossFadeState: _businessExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 220),
              sizeCurve: Curves.easeOutCubic,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepsSection(
    ColorScheme colorScheme,
    List<RouteStepEntity> steps,
    bool canExpandSteps,
    AppLocalizations l10n,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(
          children: [
            InkWell(
              onTap: canExpandSteps ? _toggleSteps : null,
              borderRadius: BorderRadius.circular(12),
              child: Row(
                children: [
                  Text(
                    l10n.map_route_steps_title,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    _stepsExpanded ? Icons.expand_less : Icons.expand_more,
                    size: 22,
                    color: canExpandSteps
                        ? colorScheme.onSurfaceVariant
                        : colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                  ),
                ],
              ),
            ),
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: _buildStepsList(context, steps),
              crossFadeState: _stepsExpanded && canExpandSteps
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 220),
              sizeCurve: Curves.easeOutCubic,
            ),
          ],
        ),
      ),
    );
  }
}

// Yuvarlak Arkaplanlı Butonlar (Frosted Design)
class _RouteActionIcon extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _RouteActionIcon({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: const Offset(0, -2),
      child: Tooltip(
        message: tooltip,
        child: AppFrostedButton(
          icon: icon,
          onTap: onTap,
          size: 34,
          iconSize: 18,
        ),
      ),
    );
  }
}

class _PoiBusinessMock {
  final String title;
  final String subtitle;
  final String distance;
  final String duration;
  final String type;
  final String rating;
  final String reviewCount;
  final String priceLevel;
  final String isOpen;
  final String address;
  final String iconUrl;
  final String? imageUrl;

  const _PoiBusinessMock(
    this.title,
    this.subtitle,
    this.distance, {
    String? duration,
    this.type = 'İşletme',
    this.rating = '4.6',
    this.reviewCount = '120',
    this.priceLevel = '',
    this.isOpen = 'Open',
    this.address = 'Bilinmiyor',
    this.iconUrl = '',
    this.imageUrl,
  }) : duration = duration ?? distance;
}

class _PoiTabItem {
  final String label;
  final IconData icon;

  const _PoiTabItem({required this.label, required this.icon});
}

List<_PoiTabItem> _buildPoiTabs(AppLocalizations l10n) {
  return [
    _PoiTabItem(label: l10n.map_poi_gas, icon: Icons.local_gas_station_rounded),
    _PoiTabItem(label: l10n.map_poi_rest, icon: Icons.local_cafe_rounded),
    _PoiTabItem(label: l10n.map_poi_service, icon: Icons.build_rounded),
    _PoiTabItem(
      label: l10n.map_poi_equipment,
      icon: Icons.sports_motorsports_rounded,
    ),
  ];
}
