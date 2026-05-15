import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:helmove/l10n/app_localizations.dart';

import '../pages/map_destination_search_page.dart';
import '../providers/map_bloc.dart';
import '../providers/map_event.dart';

class MapSearchBar extends StatefulWidget {
  const MapSearchBar({super.key});

  @override
  State<MapSearchBar> createState() => _MapSearchBarState();
}

class _MapSearchBarState extends State<MapSearchBar> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<MapBloc>().add(MapAutoFillStartFromGps());
      }
    });
  }

  void _openSearch(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<MapBloc>(),
          child: const MapDestinationSearchPage(isStart: false),
        ),
      ),
    );
  }

  void _clearDestination(BuildContext context) {
    context.read<MapBloc>().add(MapSearchFieldCleared(isStart: false));
    context.read<MapBloc>().add(MapClearRoutingRequested());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return BlocBuilder<MapBloc, MapState>(
      buildWhen: (p, c) => p.endPoint != c.endPoint,
      builder: (context, state) {
        final destination = state.endPoint;

        return GestureDetector(
          onTap: () => _openSearch(context),
          child: Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(
                  Icons.search,
                  color: theme.colorScheme.primary,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: destination != null
                      ? Text(
                          destination.label,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        )
                      : Text(
                          l10n.map_search_to,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                ),
                if (destination != null)
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _clearDestination(context),
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Icon(
                        Icons.close,
                        size: 18,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
