import '../../domain/entities/ride_entity.dart';
import '../../domain/repositories/ride_repository.dart';
import '../api/rides_api.dart';
import '../models/ride_model.dart';

class RideRepositoryImpl implements RideRepository {
  final RidesApi _api;

  RideRepositoryImpl(this._api);

  @override
  Future<({List<RideEntity> items, int total})> getMyRides({
    int page = 1,
    int limit = 20,
  }) => _api.getMyRides(page: page, limit: limit);

  @override
  Future<RideEntity> getRideById(int id) => _api.getRideById(id);

  @override
  Future<RideEntity> createRide(RideEntity ride) {
    final model = RideModel(
      title: ride.title,
      startedAt: ride.startedAt,
      endedAt: ride.endedAt,
      distanceKm: ride.distanceKm,
      durationSeconds: ride.durationSeconds,
      avgSpeedKmh: ride.avgSpeedKmh,
      maxSpeedKmh: ride.maxSpeedKmh,
      startCity: ride.startCity,
      endCity: ride.endCity,
      points: ride.points,
    );
    return _api.createRide(model.toJson());
  }

  @override
  Future<void> deleteRide(int id) => _api.deleteRide(id);
}
