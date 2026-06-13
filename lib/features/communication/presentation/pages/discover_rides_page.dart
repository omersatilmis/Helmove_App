import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';

import 'package:helmove/core/widgets/app_background.dart';
import 'package:helmove/features/group_ride/domain/entities/ride_filters.dart';
import 'package:helmove/features/group_ride/presentation/bloc/discover_rides/discover_rides_bloc.dart';
import 'package:helmove/features/group_ride/presentation/bloc/discover_rides/discover_rides_event.dart';
import 'package:helmove/features/group_ride/presentation/bloc/discover_rides/discover_rides_state.dart';
import '../widgets/ride_summary_card.dart';

/// [Keşfet] Grup turlarını ara + yakındakileri listele (ilk dilim).
class DiscoverRidesPage extends StatefulWidget {
  const DiscoverRidesPage({super.key});

  @override
  State<DiscoverRidesPage> createState() => _DiscoverRidesPageState();
}

class _DiscoverRidesPageState extends State<DiscoverRidesPage> {
  final TextEditingController _searchController = TextEditingController();
  bool _resolvingLocation = false;

  @override
  void initState() {
    super.initState();
    // İlk açılışta yaklaşan turları getir (boş query → tüm Planning turları).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<DiscoverRidesBloc>().add(const DiscoverRefreshed());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _switchToNearby() async {
    if (_resolvingLocation) return;
    setState(() => _resolvingLocation = true);
    try {
      final position = await _currentPosition();
      if (!mounted) return;
      context.read<DiscoverRidesBloc>().add(
        NearbyRequested(position.latitude, position.longitude),
      );
    } catch (e) {
      if (!mounted) return;
      // İzin/konum başarısız → search moduna geri dön + bilgi.
      context.read<DiscoverRidesBloc>().add(
        const DiscoverModeChanged(nearby: false),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _resolvingLocation = false);
    }
  }

  Future<Position> _currentPosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Konum servisleri kapalı.');
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw Exception('Konum izni gerekli.');
    }
    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: const Text('Grup Turlarını Keşfet'),
        ),
        body: SafeArea(
          top: false,
          child: Column(
            children: [
              _buildSearchBar(colorScheme),
              _buildModeToggle(colorScheme),
              _buildFilterBar(colorScheme),
              const SizedBox(height: 4),
              Expanded(child: _buildResults(colorScheme)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: TextField(
        controller: _searchController,
        onChanged: (q) =>
            context.read<DiscoverRidesBloc>().add(SearchQueryChanged(q)),
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Tur ara...',
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: ValueListenableBuilder<TextEditingValue>(
            valueListenable: _searchController,
            builder: (context, value, _) => value.text.isEmpty
                ? const SizedBox.shrink()
                : IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () {
                      _searchController.clear();
                      context.read<DiscoverRidesBloc>().add(
                        const SearchQueryChanged(''),
                      );
                    },
                  ),
          ),
          filled: true,
          fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildModeToggle(ColorScheme colorScheme) {
    return BlocBuilder<DiscoverRidesBloc, DiscoverRidesState>(
      buildWhen: (p, c) => p.mode != c.mode,
      builder: (context, state) {
        final isNearby = state.mode == DiscoverMode.nearby;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: _modeButton(
                  colorScheme,
                  label: 'Ara',
                  icon: Icons.search_rounded,
                  selected: !isNearby,
                  onTap: () => context.read<DiscoverRidesBloc>().add(
                    const DiscoverModeChanged(nearby: false),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _modeButton(
                  colorScheme,
                  label: 'Yakındakiler',
                  icon: _resolvingLocation
                      ? Icons.hourglass_top_rounded
                      : Icons.near_me_rounded,
                  selected: isNearby,
                  onTap: _resolvingLocation ? null : _switchToNearby,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _modeButton(
    ColorScheme colorScheme, {
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback? onTap,
  }) {
    return Material(
      color: selected
          ? colorScheme.primary.withValues(alpha: 0.15)
          : colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? colorScheme.primary.withValues(alpha: 0.4)
                  : Colors.transparent,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: selected ? colorScheme.primary : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: selected ? colorScheme.primary : colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterBar(ColorScheme colorScheme) {
    return BlocBuilder<DiscoverRidesBloc, DiscoverRidesState>(
      buildWhen: (p, c) =>
          p.difficulty != c.difficulty || p.ridingStyle != c.ridingStyle,
      builder: (context, state) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              _difficultyFilter(state),
              const SizedBox(width: 8),
              _styleFilter(state),
              if (state.hasFilters) ...[
                const SizedBox(width: 8),
                ActionChip(
                  avatar: const Icon(Icons.clear_rounded, size: 16),
                  label: const Text('Temizle'),
                  onPressed: () => context.read<DiscoverRidesBloc>().add(
                    const FiltersChanged(),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _difficultyFilter(DiscoverRidesState state) {
    const labels = {
      RideDifficulty.beginner: 'Başlangıç',
      RideDifficulty.intermediate: 'Orta',
      RideDifficulty.advanced: 'İleri',
      RideDifficulty.expert: 'Uzman',
    };
    return PopupMenuButton<RideDifficulty?>(
      onSelected: (v) => context.read<DiscoverRidesBloc>().add(
        FiltersChanged(difficulty: v, ridingStyle: state.ridingStyle),
      ),
      itemBuilder: (_) => [
        const PopupMenuItem(value: null, child: Text('Tüm zorluklar')),
        ...RideDifficulty.values.map(
          (d) => PopupMenuItem(value: d, child: Text(labels[d]!)),
        ),
      ],
      child: _filterChip(
        state.difficulty == null ? 'Zorluk' : labels[state.difficulty]!,
        active: state.difficulty != null,
      ),
    );
  }

  Widget _styleFilter(DiscoverRidesState state) {
    const labels = {
      RideStyle.sakin: 'Sakin',
      RideStyle.tour: 'Tur',
      RideStyle.viraj: 'Viraj',
      RideStyle.sehir: 'Şehir',
    };
    return PopupMenuButton<RideStyle?>(
      onSelected: (v) => context.read<DiscoverRidesBloc>().add(
        FiltersChanged(difficulty: state.difficulty, ridingStyle: v),
      ),
      itemBuilder: (_) => [
        const PopupMenuItem(value: null, child: Text('Tüm tarzlar')),
        ...RideStyle.values.map(
          (s) => PopupMenuItem(value: s, child: Text(labels[s]!)),
        ),
      ],
      child: _filterChip(
        state.ridingStyle == null ? 'Tarz' : labels[state.ridingStyle]!,
        active: state.ridingStyle != null,
      ),
    );
  }

  Widget _filterChip(String label, {required bool active}) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: active
            ? colorScheme.primary.withValues(alpha: 0.15)
            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: active
              ? colorScheme.primary.withValues(alpha: 0.4)
              : colorScheme.outlineVariant,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: active ? colorScheme.primary : colorScheme.onSurface,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 2),
          Icon(
            Icons.arrow_drop_down_rounded,
            size: 18,
            color: active ? colorScheme.primary : colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }

  Widget _buildResults(ColorScheme colorScheme) {
    return BlocBuilder<DiscoverRidesBloc, DiscoverRidesState>(
      builder: (context, state) {
        final showInitialLoader =
            state.status == DiscoverRidesStatus.loading && state.rides.isEmpty;
        if (showInitialLoader) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state.status == DiscoverRidesStatus.failure && state.rides.isEmpty) {
          return _ErrorView(
            message: state.error ?? 'Bir hata oluştu.',
            onRetry: () => context.read<DiscoverRidesBloc>().add(
              const DiscoverRefreshed(),
            ),
          );
        }

        if (state.rides.isEmpty) {
          return const _EmptyView();
        }

        return RefreshIndicator(
          onRefresh: () async =>
              context.read<DiscoverRidesBloc>().add(const DiscoverRefreshed()),
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: state.rides.length,
            itemBuilder: (context, i) {
              final ride = state.rides[i];
              return RideSummaryCard(
                ride: ride,
                showDistance: state.mode == DiscoverMode.nearby,
                onTap: () {
                  // Detay → sonraki adım.
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Tur detayı yakında.')),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 56,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 12),
          Text(
            'Sonuç bulunamadı',
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: 48, color: colorScheme.error),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Tekrar dene'),
            ),
          ],
        ),
      ),
    );
  }
}
