import 'package:equatable/equatable.dart';
import '../../../domain/entities/group_ride_summary.dart';
import '../../../domain/entities/ride_filters.dart';

enum DiscoverMode { search, nearby }

enum DiscoverRidesStatus { initial, loading, success, failure }

/// copyWith'te nullable alanları (difficulty/ridingStyle/error/lat/lng) null'a
/// çekebilmek için sentinel.
const Object _undefined = Object();

class DiscoverRidesState extends Equatable {
  final DiscoverMode mode;
  final DiscoverRidesStatus status;
  final String query;
  final RideDifficulty? difficulty;
  final RideStyle? ridingStyle;
  final List<GroupRideSummary> rides;
  final String? error;
  final double? lastLat;
  final double? lastLng;

  const DiscoverRidesState({
    this.mode = DiscoverMode.search,
    this.status = DiscoverRidesStatus.initial,
    this.query = '',
    this.difficulty,
    this.ridingStyle,
    this.rides = const [],
    this.error,
    this.lastLat,
    this.lastLng,
  });

  DiscoverRidesState copyWith({
    DiscoverMode? mode,
    DiscoverRidesStatus? status,
    String? query,
    Object? difficulty = _undefined,
    Object? ridingStyle = _undefined,
    List<GroupRideSummary>? rides,
    Object? error = _undefined,
    Object? lastLat = _undefined,
    Object? lastLng = _undefined,
  }) {
    return DiscoverRidesState(
      mode: mode ?? this.mode,
      status: status ?? this.status,
      query: query ?? this.query,
      difficulty: difficulty == _undefined
          ? this.difficulty
          : difficulty as RideDifficulty?,
      ridingStyle: ridingStyle == _undefined
          ? this.ridingStyle
          : ridingStyle as RideStyle?,
      rides: rides ?? this.rides,
      error: error == _undefined ? this.error : error as String?,
      lastLat: lastLat == _undefined ? this.lastLat : lastLat as double?,
      lastLng: lastLng == _undefined ? this.lastLng : lastLng as double?,
    );
  }

  bool get hasFilters => difficulty != null || ridingStyle != null;

  @override
  List<Object?> get props => [
    mode,
    status,
    query,
    difficulty,
    ridingStyle,
    rides,
    error,
    lastLat,
    lastLng,
  ];
}
