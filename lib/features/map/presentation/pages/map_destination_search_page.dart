import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:helmove/l10n/app_localizations.dart';

import '../providers/map_bloc.dart';
import '../providers/map_event.dart';
import '../providers/map_state.dart';

class MapDestinationSearchPage extends StatefulWidget {
  final bool isStart;

  const MapDestinationSearchPage({super.key, this.isStart = false});

  @override
  State<MapDestinationSearchPage> createState() =>
      _MapDestinationSearchPageState();
}

class _MapDestinationSearchPageState extends State<MapDestinationSearchPage> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
        context.read<MapBloc>().add(
          MapSearchQueryChanged(query: '', isStart: widget.isStart),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onChanged(String val) {
    setState(() {});
    context.read<MapBloc>().add(
      MapSearchQueryChanged(query: val, isStart: widget.isStart),
    );
  }

  void _clearField() {
    _controller.clear();
    setState(() {});
    context.read<MapBloc>().add(MapSearchFieldCleared(isStart: widget.isStart));
    context.read<MapBloc>().add(
      MapSearchQueryChanged(query: '', isStart: widget.isStart),
    );
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final hasText = _controller.text.isNotEmpty;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: TextField(
          controller: _controller,
          focusNode: _focusNode,
          textInputAction: TextInputAction.search,
          style: theme.textTheme.bodyLarge,
          decoration: InputDecoration(
            hintText: widget.isStart
                ? l10n.map_search_from
                : l10n.map_search_to,
            hintStyle: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            border: InputBorder.none,
          ),
          onChanged: _onChanged,
          onSubmitted: (val) {
            context.read<MapBloc>().add(
              MapSearchLocationRequested(query: val, isStart: widget.isStart),
            );
          },
        ),
        actions: [
          if (hasText)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: _clearField,
            ),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(
            height: 1,
            color: theme.colorScheme.outlineVariant,
          ),
        ),
      ),
      body: BlocBuilder<MapBloc, MapState>(
        buildWhen: (p, c) =>
            p.suggestions != c.suggestions ||
            p.isSuggesting != c.isSuggesting ||
            p.lastQuery != c.lastQuery ||
            p.searchFilters != c.searchFilters,
        builder: (context, state) {
          final hasQuery = state.lastQuery.trim().length >= 2;

          if (!hasQuery) {
            return _buildEmptyPrompt(theme, l10n);
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: _buildFilters(context, state.searchFilters, l10n),
              ),
              if (state.isSuggesting)
                const LinearProgressIndicator(minHeight: 2),
              if (!state.isSuggesting && state.suggestions.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Text(
                      l10n.noResultsFound,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: state.suggestions.length,
                  itemBuilder: (ctx, i) {
                    final item = state.suggestions[i];
                    return ListTile(
                      leading: Icon(
                        Icons.place_outlined,
                        color: theme.colorScheme.primary,
                      ),
                      title: Text(
                        item.label,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium,
                      ),
                      onTap: () {
                        context.read<MapBloc>().add(
                          MapSearchSuggestionSelected(
                            location: item,
                            isStart: widget.isStart,
                          ),
                        );
                        Navigator.of(context).pop();
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyPrompt(ThemeData theme, AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            widget.isStart ? Icons.my_location_outlined : Icons.search,
            size: 56,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.35),
          ),
          const SizedBox(height: 16),
          Text(
            widget.isStart
                ? 'Başlangıç noktasını yazın'
                : 'Gitmek istediğiniz yeri yazın',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(
    BuildContext context,
    MapSearchFilters filters,
    AppLocalizations l10n,
  ) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        FilterChip(
          label: Text(l10n.map_filter_nearby),
          selected: filters.useProximity,
          onSelected: (v) => _updateFilters(
            context,
            filters.copyWith(useProximity: v),
          ),
        ),
        FilterChip(
          label: Text(l10n.map_filter_this_area),
          selected: filters.useMapBounds,
          onSelected: (v) => _updateFilters(
            context,
            filters.copyWith(useMapBounds: v),
          ),
        ),
        FilterChip(
          label: Text(l10n.map_filter_address),
          selected: filters.types.contains('address'),
          onSelected: (v) => _toggleType(context, filters, 'address', v),
        ),
        FilterChip(
          label: Text(l10n.map_filter_poi),
          selected: filters.types.contains('poi'),
          onSelected: (v) => _toggleType(context, filters, 'poi', v),
        ),
        FilterChip(
          label: Text(l10n.map_filter_city),
          selected: filters.types.contains('place'),
          onSelected: (v) => _toggleType(context, filters, 'place', v),
        ),
      ],
    );
  }

  void _toggleType(
    BuildContext context,
    MapSearchFilters filters,
    String type,
    bool enabled,
  ) {
    final updated = Set<String>.from(filters.types);
    if (enabled) updated.add(type); else updated.remove(type);
    _updateFilters(context, filters.copyWith(types: updated));
  }

  void _updateFilters(BuildContext context, MapSearchFilters filters) {
    context.read<MapBloc>().add(MapSearchFiltersUpdated(filters));
  }
}
