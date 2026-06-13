import 'package:equatable/equatable.dart';
import '../../../domain/entities/ride_filters.dart';

sealed class DiscoverRidesEvent extends Equatable {
  const DiscoverRidesEvent();

  @override
  List<Object?> get props => [];
}

/// Arama metni değişti (debounce'lu).
class SearchQueryChanged extends DiscoverRidesEvent {
  final String query;
  const SearchQueryChanged(this.query);

  @override
  List<Object?> get props => [query];
}

/// Filtreler değişti — tüm filtre setini taşır (null = temizle).
class FiltersChanged extends DiscoverRidesEvent {
  final RideDifficulty? difficulty;
  final RideStyle? ridingStyle;
  const FiltersChanged({this.difficulty, this.ridingStyle});

  @override
  List<Object?> get props => [difficulty, ridingStyle];
}

/// Mod değişti (Ara ↔ Yakındakiler).
class DiscoverModeChanged extends DiscoverRidesEvent {
  final bool nearby;
  const DiscoverModeChanged({required this.nearby});

  @override
  List<Object?> get props => [nearby];
}

/// Yakındaki turlar istendi (konum UI'da alınıp geçirilir).
class NearbyRequested extends DiscoverRidesEvent {
  final double latitude;
  final double longitude;
  const NearbyRequested(this.latitude, this.longitude);

  @override
  List<Object?> get props => [latitude, longitude];
}

/// Mevcut mod/filtrelerle yeniden yükle (pull-to-refresh / retry).
class DiscoverRefreshed extends DiscoverRidesEvent {
  const DiscoverRefreshed();
}
