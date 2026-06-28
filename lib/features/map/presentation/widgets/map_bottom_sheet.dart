import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:helmove/l10n/app_localizations.dart';
import '../../domain/entities/location_entity.dart';
import '../providers/map_bloc.dart';
import 'map_bottom_sheet_destination.dart';
import 'map_bottom_sheet_route.dart';
import 'map_bottom_sheet_add_stop.dart';

class MapBottomSheet extends StatelessWidget {
  final bool forceCollapsed;
  final double? bottomBarHeight;

  /// Grup sürüşü rota planlama modu — navigasyon başlat butonunu gizlemek için
  /// alt rota sheet'ine iletilir.
  final bool planningMode;

  const MapBottomSheet({
    super.key,
    this.forceCollapsed = false,
    this.bottomBarHeight,
    this.planningMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) {
      return const SizedBox.shrink();
    }

    return BlocBuilder<MapBloc, MapState>(
      builder: (context, state) {
        final hasRoute = state.isRouteActive && state.routeOptions.isNotEmpty;
        final location = state.selectedLocation;

        if (!hasRoute && location == null) {
          return const SizedBox.shrink(key: ValueKey('empty'));
        }

        final content = state.isSelectingStopFromMap
            ? MapBottomSheetDestination(
                location: location ??
                    LocationEntity(
                      point: Point(coordinates: Position(0, 0)),
                      label: l10n.map_select_stop_hint,
                    ),
                isLoading: state.isGeocoding,
                canRoute: false,
                isSelectionMode: true,
                startPoint: state.startPoint,
                endPoint: state.endPoint,
                stops: state.stops,
              )
            : (state.isAddStopVisible
                ? MapBottomSheetAddStop(bottomBarHeight: bottomBarHeight)
                : (hasRoute
                    ? MapBottomSheetRoute(
                        routes: state.routeOptions,
                        selectedIndex: state.selectedRouteIndex,
                        selectedStepIndex: state.selectedStepIndex,
                        startPoint: state.startPoint,
                        stops: state.stops,
                        endPoint: state.endPoint,
                        planningMode: planningMode,
                      )
                    : MapBottomSheetDestination(
                        location: location!,
                        isLoading: state.isGeocoding,
                        canRoute:
                            state.startPoint != null && state.endPoint != null,
                        startPoint: state.startPoint,
                        endPoint: state.endPoint,
                      )));

        // Key sadece içerik TİPİ değişince değişsin — böylece rota index'i
        // değiştiğinde (aynı route ekranı) sheet baştan slide-in yapmaz,
        // sadece içeriği güncellenir.
        final key = state.isSelectingStopFromMap
            ? const ValueKey('selecting_stop')
            : (state.isAddStopVisible
                ? const ValueKey('add_stop')
                : (hasRoute
                    ? const ValueKey('route')
                    : const ValueKey('destination')));

        return _ExpandableSheet(
          key: key,
          content: content,
          forceCollapsed: forceCollapsed ||
              (state.isSelectingStopFromMap && location == null),
          bottomBarHeight: bottomBarHeight,
          isExpandable: hasRoute,
        );
      },
    );
  }
}

class BottomSheetStateProvider extends InheritedWidget {
  final int snapIndex;
  final void Function(int index) setSnapIndex;

  const BottomSheetStateProvider({
    super.key,
    required this.snapIndex,
    required this.setSnapIndex,
    required super.child,
  });

  static BottomSheetStateProvider? of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<BottomSheetStateProvider>();
  }

  @override
  bool updateShouldNotify(BottomSheetStateProvider oldWidget) {
    return oldWidget.snapIndex != snapIndex;
  }
}

class _ExpandableSheet extends StatefulWidget {
  final Widget content;
  final bool forceCollapsed;
  final double? bottomBarHeight;
  final bool isExpandable;

  const _ExpandableSheet({
    super.key,
    required this.content,
    required this.forceCollapsed,
    this.bottomBarHeight,
    this.isExpandable = true,
  });

  @override
  State<_ExpandableSheet> createState() => _ExpandableSheetState();
}

class _ExpandableSheetState extends State<_ExpandableSheet>
    with SingleTickerProviderStateMixin {
  int _snapIndex = 1; // 0: collapsed, 1: expanded (full)
  double? _activeHeight;
  bool _isDragging = false;
  final GlobalKey _contentKey = GlobalKey();

  late final AnimationController _slideCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 340),
  );

  @override
  void initState() {
    super.initState();
    if (widget.forceCollapsed || !widget.isExpandable) {
      _snapIndex = 0;
    }
    _slideCtrl.forward();
  }

  @override
  void dispose() {
    _slideCtrl.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _ExpandableSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if ((widget.forceCollapsed || !widget.isExpandable) && 
        !(oldWidget.forceCollapsed || !oldWidget.isExpandable) && 
        _snapIndex != 0) {
      setState(() {
        _snapIndex = 0;
        _activeHeight = null;
      });
    } else if (!(widget.forceCollapsed || !widget.isExpandable) &&
        (oldWidget.forceCollapsed || !oldWidget.isExpandable) &&
        _snapIndex == 0) {
      setState(() {
        _snapIndex = 1;
        _activeHeight = null;
      });
    }
  }

  // İki snap: 0 = collapsed (küçük peek), 1 = expanded (full).
  double _collapsedHeight(double maxHeight, double bottomAdjustment) =>
      maxHeight * 0.26 + bottomAdjustment;
  double _expandedHeight(double maxHeight, double bottomAdjustment) =>
      maxHeight + bottomAdjustment;

  void _toggleExpand() {
    setState(() {
      _snapIndex = _snapIndex == 0 ? 1 : 0;
      _activeHeight = null;
    });
  }

  void _handleDragStart(DragStartDetails details) {
    // Gerçek içerik kutusunu ölç (dış wrapper'ı değil) — aksi halde drag
    // başında sheet bir anda büyüyüp/küçülüp zıplıyordu.
    final box = _contentKey.currentContext?.findRenderObject() as RenderBox?;
    final topSafe = MediaQuery.viewPaddingOf(context).top;
    final bottomAdjustment = widget.bottomBarHeight ?? 0;
    final maxHeight =
        MediaQuery.sizeOf(context).height - topSafe - 8 - bottomAdjustment;
    final fallback = _snapIndex == 1
        ? _expandedHeight(maxHeight, bottomAdjustment)
        : _collapsedHeight(maxHeight, bottomAdjustment);
    setState(() {
      _isDragging = true;
      _activeHeight = (box != null && box.hasSize) ? box.size.height : fallback;
    });
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    setState(() {
      _activeHeight = (_activeHeight ?? 100) - details.delta.dy;
    });
  }

  void _handleDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    final topSafe = MediaQuery.viewPaddingOf(context).top;
    final bottomAdjustment = widget.bottomBarHeight ?? 0;
    final maxHeight =
        MediaQuery.sizeOf(context).height - topSafe - 8 - bottomAdjustment;

    final collapsedH = _collapsedHeight(maxHeight, bottomAdjustment);
    final expandedH = _expandedHeight(maxHeight, bottomAdjustment);
    final currentH = _activeHeight ?? collapsedH;

    int targetIndex;
    if (velocity < -400) {
      targetIndex = 1; // yukarı fling → aç
    } else if (velocity > 400) {
      targetIndex = 0; // aşağı fling → kapat
    } else {
      // En yakına snap — ortada durma yok, sadece iki uç.
      targetIndex =
          (currentH - collapsedH).abs() <= (currentH - expandedH).abs() ? 0 : 1;
    }

    setState(() {
      _snapIndex = targetIndex;
      _isDragging = false;
      _activeHeight = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final topSafe = MediaQuery.viewPaddingOf(context).top;
    final bottomAdjustment = widget.bottomBarHeight ?? 0;
    final maxHeight =
        MediaQuery.sizeOf(context).height - topSafe - 8 - bottomAdjustment;

    final bool expanded = _snapIndex == 1;

    // Destination (isExpandable=false): content-driven (null).
    // Route: iki snap — collapsed (sabit peek) / expanded (full).
    final double? baseTargetHeight;
    if (!widget.isExpandable) {
      baseTargetHeight = null;
    } else if (widget.forceCollapsed) {
      baseTargetHeight = _collapsedHeight(maxHeight, bottomAdjustment);
    } else {
      baseTargetHeight = expanded
          ? _expandedHeight(maxHeight, bottomAdjustment)
          : _collapsedHeight(maxHeight, bottomAdjustment);
    }

    final displayHeight = _isDragging ? _activeHeight : baseTargetHeight;

    final contentPadding = EdgeInsets.fromLTRB(16, 4, 16, bottomAdjustment);

    final sheet = AnimatedContainer(
      duration: _isDragging ? Duration.zero : const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      width: double.infinity,
      height: displayHeight,
      constraints: BoxConstraints(maxHeight: maxHeight + bottomAdjustment),
      child: BottomSheetStateProvider(
        snapIndex: widget.forceCollapsed ? 0 : _snapIndex,
        setSnapIndex: (index) {
          setState(() {
            _snapIndex = index;
            _activeHeight = null;
          });
        },
        child: Material(
          color: theme.colorScheme.surface,
          elevation: 12,
          shadowColor: Colors.black.withValues(alpha: 0.18),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          clipBehavior: Clip.antiAlias,
          child: Column(
            key: _contentKey,
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: widget.isExpandable ? _toggleExpand : null,
                onVerticalDragStart: widget.isExpandable ? _handleDragStart : null,
                onVerticalDragUpdate: widget.isExpandable ? _handleDragUpdate : null,
                onVerticalDragEnd: widget.isExpandable ? _handleDragEnd : null,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.25,
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ),
              Flexible(
                // Expanded route sheet maxHeight'i doldurur ve scroll eder;
                // collapsed/destination doğal boyutta, scroll kapalı.
                fit: (widget.isExpandable && expanded)
                    ? FlexFit.tight
                    : FlexFit.loose,
                child: SingleChildScrollView(
                  physics: (widget.isExpandable && expanded)
                      ? const BouncingScrollPhysics()
                      : const NeverScrollableScrollPhysics(),
                  padding: contentPadding,
                  child: widget.content,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    // Slide-in: boyuttan bağımsız (paint-time FractionalTranslation), layout'u
    // etkilemez → height değişimiyle çakışmaz. child param olarak verildiği
    // için alt tree slide boyunca rebuild olmaz.
    return AnimatedBuilder(
      animation: _slideCtrl,
      builder: (context, child) {
        final t = Curves.easeOutCubic.transform(_slideCtrl.value);
        return FractionalTranslation(
          translation: Offset(0, 1 - t),
          child: child,
        );
      },
      child: sheet,
    );
  }
}
