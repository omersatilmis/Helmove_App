import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../providers/map_bloc.dart';
import '../providers/map_event.dart';

class RoutePoiPanel extends StatelessWidget {
  final double? bottomBarHeight;

  const RoutePoiPanel({
    super.key,
    this.bottomBarHeight,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<MapBloc, MapState>(
      builder: (context, state) {
        if (!state.isRouteActive || state.routePois.isEmpty) {
          return const SizedBox.shrink();
        }

        final selectedIndex = state.selectedPoiIndex;

        return Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            0,
            16,
            160 + (bottomBarHeight ?? 0),
          ),
          child: Material(
            color: theme.colorScheme.surface,
            elevation: 8,
            shadowColor: Colors.black.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.place_rounded,
                        size: 16,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Yol Üstü Noktalar',
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${state.routePois.length}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 36,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: state.routePois.length,
                      separatorBuilder: (_, index) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final poi = state.routePois[index];
                        final isSelected = selectedIndex == index;
                        return ChoiceChip(
                          selected: isSelected,
                          onSelected: (_) => context
                              .read<MapBloc>()
                              .add(MapRoutePoiSelected(index)),
                          avatar: Icon(
                            Icons.place_outlined,
                            size: 16,
                            color: isSelected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                          label: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 140),
                            child: Text(
                              poi.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          labelStyle: theme.textTheme.bodySmall?.copyWith(
                            color: isSelected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurface,
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.w500,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 6,
                          ),
                          backgroundColor:
                              theme.colorScheme.surfaceContainerHighest
                                  .withValues(alpha: 0.6),
                          selectedColor:
                              theme.colorScheme.primaryContainer.withValues(
                                alpha: 0.7,
                              ),
                          side: BorderSide(
                            color: isSelected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.outline.withValues(
                                    alpha: 0.2,
                                  ),
                          ),
                          shape: const StadiumBorder(),
                          visualDensity: VisualDensity.compact,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
