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

  const MapBottomSheet({
    super.key,
    this.forceCollapsed = false,
    this.bottomBarHeight,
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
                      )
                    : MapBottomSheetDestination(
                        location: location!,
                        isLoading: state.isGeocoding,
                        canRoute:
                            state.startPoint != null && state.endPoint != null,
                        startPoint: state.startPoint,
                        endPoint: state.endPoint,
                      )));

        final key = state.isSelectingStopFromMap
            ? const ValueKey('selecting_stop')
            : (state.isAddStopVisible
                ? const ValueKey('add_stop')
                : (hasRoute
                    ? ValueKey(
                        'route_${state.selectedRouteIndex}_${state.routeOptions.length}',
                      )
                    : ValueKey(location!.point.toString())));

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 320),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (Widget child, Animation<double> animation) {
            final offsetAnimation = Tween<Offset>(
              begin: const Offset(0.0, 1.2),
              end: Offset.zero,
            ).animate(animation);
            return SlideTransition(position: offsetAnimation, child: child);
          },
          child: _ExpandableSheet(
            key: key,
            content: content,
            forceCollapsed: forceCollapsed ||
                (state.isSelectingStopFromMap && location == null),
            bottomBarHeight: bottomBarHeight,
            isExpandable: hasRoute,
          ),
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

class _ExpandableSheetState extends State<_ExpandableSheet> {
  int _snapIndex = 1; // 0: low, 1: mid, 2: full
  double? _activeHeight;
  bool _isDragging = false;
  final Map<int, double> _measuredHeights = {};
  final GlobalKey _contentKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    if (widget.forceCollapsed || !widget.isExpandable) {
      _snapIndex = 0;
    }
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

  void _toggleExpand() {
    setState(() {
      _snapIndex = (_snapIndex + 1) % 3;
      _activeHeight = null;
    });
  }

  void _handleDragStart(DragStartDetails details) {
    setState(() {
      _isDragging = true;
      // Capture current height before starting drag
      final box = context.findRenderObject() as RenderBox?;
      _activeHeight = box?.size.height ?? 100;
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
    final maxHeight = MediaQuery.sizeOf(context).height - topSafe - 8;

    // Default fallbacks if not yet measured
    final lowH = _measuredHeights[0] ?? (maxHeight * 0.23 + bottomAdjustment);
    final midH = _measuredHeights[1] ?? (maxHeight * 0.5 + bottomAdjustment);
    final fullH = maxHeight + bottomAdjustment;

    final currentH = _activeHeight ?? lowH;
    int targetIndex = _snapIndex;

    if (velocity < -500) {
      targetIndex = (_snapIndex + 1).clamp(0, 2);
    } else if (velocity > 500) {
      targetIndex = (_snapIndex - 1).clamp(0, 2);
    } else {
      // Snap to nearest
      final d0 = (currentH - lowH).abs();
      final d1 = (currentH - midH).abs();
      final d2 = (currentH - fullH).abs();

      if (d0 <= d1 && d0 <= d2) {
        targetIndex = 0;
      } else if (d1 <= d0 && d1 <= d2) {
        targetIndex = 1;
      } else {
        targetIndex = 2;
      }
    }

    setState(() {
      _snapIndex = targetIndex;
      _isDragging = false;
      _activeHeight = null; // Snap back to content-driven or max height
    });
  }

  void _recordHeight() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _isDragging) return;
      final box = _contentKey.currentContext?.findRenderObject() as RenderBox?;
      if (box != null && box.hasSize) {
        final h = box.size.height;
        if (_measuredHeights[_snapIndex] != h) {
          _measuredHeights[_snapIndex] = h;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    _recordHeight();
    final theme = Theme.of(context);
    final topSafe = MediaQuery.viewPaddingOf(context).top;
    final bottomAdjustment = widget.bottomBarHeight ?? 0;
    final maxHeight =
        MediaQuery.sizeOf(context).height - topSafe - 8 - bottomAdjustment;

    final double? targetHeightInner = _snapIndex == 2
      ? maxHeight
      : (_snapIndex == 1
          ? (_measuredHeights[1] ?? (maxHeight * 0.5))
          : null);

    final double? baseTargetHeight = widget.forceCollapsed
        ? null
        : (targetHeightInner != null
              ? targetHeightInner + bottomAdjustment
              : null);

    final displayHeight = _isDragging ? _activeHeight : baseTargetHeight;

    final contentPadding = EdgeInsets.fromLTRB(16, 4, 16, bottomAdjustment);

    return AnimatedContainer(
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
                fit: _snapIndex == 2 ? FlexFit.tight : FlexFit.loose,
                child: SingleChildScrollView(
                  physics: _snapIndex >= 1
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
  }
}
