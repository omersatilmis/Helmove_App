import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:helmove/l10n/app_localizations.dart';
import '../../../../core/widgets/app_input_field.dart';
import '../providers/map_bloc.dart';
import '../providers/map_event.dart';

class MapSearchBar extends StatefulWidget {
  final Key? fieldsKey;

  const MapSearchBar({super.key, this.fieldsKey});

  @override
  State<MapSearchBar> createState() => _MapSearchBarState();
}

class _MapSearchBarState extends State<MapSearchBar> {
  late final TextEditingController _startController;
  late final TextEditingController _endController;
  late final FocusNode _startFocus;
  late final FocusNode _endFocus;
  bool _suppressNextChange = false;

  @override
  void initState() {
    super.initState();
    _startController = TextEditingController();
    _endController = TextEditingController();
    _startFocus = FocusNode();
    _endFocus = FocusNode();
  }

  @override
  void dispose() {
    _startController.dispose();
    _endController.dispose();
    _startFocus.dispose();
    _endFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<MapBloc, MapState>(
      listener: (context, state) {
        final startFocused = _startFocus.hasFocus;
        final endFocused = _endFocus.hasFocus;

        if (state.startPoint == null) {
          if (!startFocused && _startController.text.isNotEmpty) {
            _startController.clear();
          }
        } else if (_startController.text != state.startPoint!.label) {
          _startController.text = state.startPoint!.label;
        }

        if (state.endPoint == null) {
          if (!endFocused && _endController.text.isNotEmpty) {
            _endController.clear();
          }
        } else if (_endController.text != state.endPoint!.label) {
          _endController.text = state.endPoint!.label;
        }
      },
      builder: (context, state) {
        final isSearching = state.isSearching;
        final showSuggestions = state.lastQuery.trim().length >= 2;
        final l10n = AppLocalizations.of(context)!;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              key: widget.fieldsKey,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isSearching)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 6),
                    child: LinearProgressIndicator(minHeight: 2),
                  ),
                _buildField(
                  controller: _startController,
                  focusNode: _startFocus,
                  hint: l10n.map_search_from,
                  icon: Icons.circle_outlined,
                  isStart: true,
                  isSearching: isSearching,
                ),
                const SizedBox(height: 8),
                _buildField(
                  controller: _endController,
                  focusNode: _endFocus,
                  hint: l10n.map_search_to,
                  icon: Icons.flag_outlined,
                  isStart: false,
                  isSearching: isSearching,
                ),
              ],
            ),
            if (showSuggestions) _buildSuggestionsPanel(context, state),
          ],
        );
      },
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hint,
    required IconData icon,
    required bool isStart,
    required bool isSearching,
  }) {
    final hasText = controller.text.trim().isNotEmpty;
    final trailingIcon = hasText ? Icons.close : Icons.search;
    final canSearch = !isSearching && !hasText;
    final canClear = hasText;

    return AppInputField(
      controller: controller,
      focusNode: focusNode,
      hint: hint,
      leadingIcon: icon,
      trailingIcon: trailingIcon,
      onTrailingTap: canClear
          ? () => _clearField(isStart, controller)
          : (canSearch
                ? () => context.read<MapBloc>().add(
                    MapSearchLocationRequested(
                      query: controller.text,
                      isStart: isStart,
                    ),
                  )
                : null),
      onFieldSubmitted: isSearching
          ? null
          : (val) => context.read<MapBloc>().add(
              MapSearchLocationRequested(query: val, isStart: isStart),
            ),
      onChanged: (val) => _handleChanged(val, isStart),
      textInputAction: isStart ? TextInputAction.next : TextInputAction.done,
      variant: AppInputVariant.filled,
      size: AppInputSize.small,
      showFocusBorder: false,
      verticalPadding: 10.0,
    );
  }

  void _handleChanged(String value, bool isStart) {
    if (_suppressNextChange) {
      _suppressNextChange = false;
      return;
    }
    context.read<MapBloc>().add(
      MapSearchQueryChanged(query: value, isStart: isStart),
    );
    if (value.trim().isEmpty) {
      context.read<MapBloc>().add(MapSearchFieldCleared(isStart: isStart));
    }
  }

  void _clearField(bool isStart, TextEditingController controller) {
    _suppressNextChange = true;
    controller.clear();
    context.read<MapBloc>().add(MapSearchFieldCleared(isStart: isStart));
    context.read<MapBloc>().add(
      MapSearchQueryChanged(query: '', isStart: isStart),
    );
    setState(() {});
  }

  Widget _buildSuggestionsPanel(BuildContext context, MapState state) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFilters(context, state.searchFilters),
          const SizedBox(height: 8),
          if (state.isSuggesting)
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: LinearProgressIndicator(minHeight: 2),
            ),
          if (!state.isSuggesting && state.suggestions.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                l10n.noResultsFound,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          if (state.suggestions.isNotEmpty)
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 240),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: state.suggestions.length,
                separatorBuilder: (_, _) => const SizedBox(height: 6),
                itemBuilder: (context, index) {
                  final item = state.suggestions[index];
                  return InkWell(
                    onTap: () => context.read<MapBloc>().add(
                      MapSearchSuggestionSelected(
                        location: item,
                        isStart: state.searchTargetIsStart,
                      ),
                    ),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.place_outlined,
                            size: 18,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item.label,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilters(BuildContext context, MapSearchFilters filters) {
    final l10n = AppLocalizations.of(context)!;
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        FilterChip(
          label: Text(l10n.map_filter_nearby),
          selected: filters.useProximity,
          onSelected: (value) =>
              _updateFilters(filters.copyWith(useProximity: value)),
        ),
        FilterChip(
          label: Text(l10n.map_filter_this_area),
          selected: filters.useMapBounds,
          onSelected: (value) =>
              _updateFilters(filters.copyWith(useMapBounds: value)),
        ),
        FilterChip(
          label: Text(l10n.map_filter_address),
          selected: filters.types.contains('address'),
          onSelected: (value) => _toggleType(filters, 'address', value),
        ),
        FilterChip(
          label: Text(l10n.map_filter_poi),
          selected: filters.types.contains('poi'),
          onSelected: (value) => _toggleType(filters, 'poi', value),
        ),
        FilterChip(
          label: Text(l10n.map_filter_city),
          selected: filters.types.contains('place'),
          onSelected: (value) => _toggleType(filters, 'place', value),
        ),
      ],
    );
  }

  void _toggleType(MapSearchFilters filters, String type, bool enabled) {
    final updated = Set<String>.from(filters.types);
    if (enabled) {
      updated.add(type);
    } else {
      updated.remove(type);
    }
    _updateFilters(filters.copyWith(types: updated));
  }

  void _updateFilters(MapSearchFilters filters) {
    context.read<MapBloc>().add(MapSearchFiltersUpdated(filters));
  }
}
