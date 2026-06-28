import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rxdart/rxdart.dart';

import '../../../domain/entities/group_ride_summary.dart';
import '../../../domain/usecases/search_group_rides_usecase.dart';
import '../../../domain/usecases/get_nearby_group_rides_usecase.dart';
import 'discover_rides_event.dart';
import 'discover_rides_state.dart';

/// [Keşfet] Grup turlarını arama + yakındakiler bloc'u.
///
/// Tek state + copyWith. Arama debounce'lu; nearby konumu UI'dan gelir
/// (bloc Geolocator'a bağlı değil). Keşfette yaklaşan turlar gösterilir
/// (status: Planning).
class DiscoverRidesBloc extends Bloc<DiscoverRidesEvent, DiscoverRidesState> {
  final SearchGroupRidesUseCase searchGroupRides;
  final GetNearbyGroupRidesUseCase getNearbyGroupRides;

  static const String _discoverStatus = 'Planning';
  static const double _nearbyRadiusKm = 50;

  DiscoverRidesBloc({
    required this.searchGroupRides,
    required this.getNearbyGroupRides,
  }) : super(const DiscoverRidesState()) {
    on<SearchQueryChanged>(
      _onQuery,
      transformer: (events, mapper) =>
          events.debounceTime(const Duration(milliseconds: 400)).switchMap(mapper),
    );
    on<FiltersChanged>(_onFilters);
    on<DiscoverModeChanged>(_onMode);
    on<NearbyRequested>(_onNearby);
    on<DiscoverRefreshed>(_onRefresh);
    on<LoadMoreRequested>(_onLoadMore);
  }

  Future<void> _onQuery(
    SearchQueryChanged event,
    Emitter<DiscoverRidesState> emit,
  ) async {
    emit(state.copyWith(query: event.query, mode: DiscoverMode.search));
    await _loadSearch(emit);
  }

  Future<void> _onFilters(
    FiltersChanged event,
    Emitter<DiscoverRidesState> emit,
  ) async {
    emit(
      state.copyWith(
        difficulty: event.difficulty,
        ridingStyle: event.ridingStyle,
      ),
    );
    // Filtreler her iki modda da geçerli; mevcut moda göre yeniden yükle.
    await _reload(emit);
  }

  Future<void> _onMode(
    DiscoverModeChanged event,
    Emitter<DiscoverRidesState> emit,
  ) async {
    final mode = event.nearby ? DiscoverMode.nearby : DiscoverMode.search;
    emit(state.copyWith(mode: mode));
    if (mode == DiscoverMode.search) {
      await _loadSearch(emit);
    }
    // nearby moduna geçişte konum UI'dan NearbyRequested ile gelecek.
  }

  Future<void> _onNearby(
    NearbyRequested event,
    Emitter<DiscoverRidesState> emit,
  ) async {
    emit(
      state.copyWith(
        mode: DiscoverMode.nearby,
        lastLat: event.latitude,
        lastLng: event.longitude,
      ),
    );
    await _loadNearby(emit, event.latitude, event.longitude);
  }

  Future<void> _onRefresh(
    DiscoverRefreshed event,
    Emitter<DiscoverRidesState> emit,
  ) async {
    await _reload(emit);
  }

  Future<void> _reload(Emitter<DiscoverRidesState> emit) async {
    if (state.mode == DiscoverMode.nearby) {
      final lat = state.lastLat;
      final lng = state.lastLng;
      if (lat != null && lng != null) {
        await _loadNearby(emit, lat, lng);
      }
    } else {
      await _loadSearch(emit);
    }
  }

  Future<void> _loadSearch(Emitter<DiscoverRidesState> emit) async {
    emit(
      state.copyWith(
        status: DiscoverRidesStatus.loading,
        error: null,
        isLoadingMore: false,
      ),
    );
    final result = await searchGroupRides.execute(
      SearchGroupRidesParams(
        title: state.query.isEmpty ? null : state.query,
        difficulty: state.difficulty,
        ridingStyle: state.ridingStyle,
        status: _discoverStatus,
        page: 1,
      ),
    );
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: DiscoverRidesStatus.failure,
          error: _clean(failure.message),
        ),
      ),
      (res) => emit(
        state.copyWith(
          status: DiscoverRidesStatus.success,
          rides: res.items,
          page: res.page,
          hasMore: res.hasMore,
          totalCount: res.totalCount,
          isLoadingMore: false,
        ),
      ),
    );
  }

  /// Sonsuz kaydırma: sonraki sayfayı çekip mevcut listeye ekler. Yalnız search
  /// modunda + hasMore + zaten yüklenmiyor iken çalışır. Hata olursa liste korunur,
  /// sadece spinner kapanır (kullanıcı tekrar deneyebilir).
  Future<void> _onLoadMore(
    LoadMoreRequested event,
    Emitter<DiscoverRidesState> emit,
  ) async {
    if (state.mode != DiscoverMode.search) return;
    if (!state.hasMore || state.isLoadingMore) return;
    if (state.status == DiscoverRidesStatus.loading) return;

    emit(state.copyWith(isLoadingMore: true));
    final nextPage = state.page + 1;
    final result = await searchGroupRides.execute(
      SearchGroupRidesParams(
        title: state.query.isEmpty ? null : state.query,
        difficulty: state.difficulty,
        ridingStyle: state.ridingStyle,
        status: _discoverStatus,
        page: nextPage,
      ),
    );
    result.fold(
      (failure) => emit(state.copyWith(isLoadingMore: false)),
      (res) => emit(
        state.copyWith(
          rides: [...state.rides, ...res.items],
          page: res.page,
          hasMore: res.hasMore,
          totalCount: res.totalCount,
          isLoadingMore: false,
        ),
      ),
    );
  }

  Future<void> _loadNearby(
    Emitter<DiscoverRidesState> emit,
    double lat,
    double lng,
  ) async {
    emit(state.copyWith(status: DiscoverRidesStatus.loading, error: null));
    final result = await getNearbyGroupRides.execute(
      GetNearbyGroupRidesParams(
        latitude: lat,
        longitude: lng,
        radiusKm: _nearbyRadiusKm,
      ),
    );
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: DiscoverRidesStatus.failure,
          error: _clean(failure.message),
        ),
      ),
      (rides) {
        // Backend startDateTime'a göre sıralı döner; kullanıcı için mesafeye göre.
        final sorted = List<GroupRideSummary>.from(rides)
          ..sort((a, b) => (a.distanceKm ?? double.infinity).compareTo(
            b.distanceKm ?? double.infinity,
          ));
        emit(
          state.copyWith(
            status: DiscoverRidesStatus.success,
            rides: sorted,
            // nearby sayfalı değil → load-more kapalı.
            hasMore: false,
            isLoadingMore: false,
            page: 1,
          ),
        );
      },
    );
  }

  String _clean(String raw) => raw.replaceFirst(RegExp(r'^Exception:\s*'), '').trim();
}
