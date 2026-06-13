import 'dart:async';

import 'package:flutter/material.dart';

import 'package:helmove/core/di/injection_container.dart';
import 'package:helmove/features/map/domain/entities/location_entity.dart';
import 'package:helmove/features/map/domain/usecases/search_location_suggestions_usecase.dart';

/// Grup sürüşü başlangıç noktası seçici.
///
/// Mevcut Mapbox forward-geocode usecase'i ([SearchLocationSuggestionsUseCase])
/// yeniden kullanılır. Seçilen yer `Navigator.pop` ile [LocationEntity] olarak
/// döner; geri tuşuyla çıkılırsa `null` döner.
class StartLocationPickerPage extends StatefulWidget {
  const StartLocationPickerPage({super.key});

  @override
  State<StartLocationPickerPage> createState() =>
      _StartLocationPickerPageState();
}

class _StartLocationPickerPageState extends State<StartLocationPickerPage> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  Timer? _debounce;
  List<LocationEntity> _results = const [];
  bool _loading = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onChanged(String q) {
    _debounce?.cancel();
    final query = q.trim();
    if (query.length < 2) {
      setState(() {
        _results = const [];
        _loading = false;
      });
      return;
    }
    setState(() => _loading = true);
    _debounce = Timer(
      const Duration(milliseconds: 400),
      () => _search(query),
    );
  }

  Future<void> _search(String query) async {
    if (!sl.isRegistered<SearchLocationSuggestionsUseCase>()) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    try {
      final res = await sl<SearchLocationSuggestionsUseCase>()(
        query,
        types: const ['place', 'locality', 'district', 'address', 'poi'],
        limit: 8,
      );
      if (!mounted) return;
      setState(() {
        _results = res;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _results = const [];
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
          autofocus: true,
          textInputAction: TextInputAction.search,
          style: theme.textTheme.bodyLarge,
          decoration: InputDecoration(
            hintText: 'Başlangıç noktasını yazın',
            hintStyle: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            border: InputBorder.none,
          ),
          onChanged: _onChanged,
        ),
        actions: [
          if (hasText)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                _controller.clear();
                _onChanged('');
                _focusNode.requestFocus();
              },
            ),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: theme.colorScheme.outlineVariant),
        ),
      ),
      body: Column(
        children: [
          if (_loading) const LinearProgressIndicator(minHeight: 2),
          Expanded(child: _buildBody(theme)),
        ],
      ),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_controller.text.trim().length < 2) {
      return _centerHint(
        theme,
        Icons.my_location_outlined,
        'Başlangıç noktasını aramak için yazmaya başlayın',
      );
    }
    if (!_loading && _results.isEmpty) {
      return _centerHint(theme, Icons.search_off_rounded, 'Sonuç bulunamadı');
    }
    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: _results.length,
      itemBuilder: (ctx, i) {
        final item = _results[i];
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
          subtitle: item.subtitle != null && item.subtitle!.isNotEmpty
              ? Text(
                  item.subtitle!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                )
              : null,
          onTap: () => Navigator.of(context).pop(item),
        );
      },
    );
  }

  Widget _centerHint(ThemeData theme, IconData icon, String text) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 52,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.35),
            ),
            const SizedBox(height: 14),
            Text(
              text,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
