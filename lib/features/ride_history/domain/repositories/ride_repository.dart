import '../entities/ride_entity.dart';

abstract class RideRepository {
  Future<({List<RideEntity> items, int total})> getMyRides({
    int page = 1,
    int limit = 20,
  });
  Future<RideEntity> getRideById(int id);
  Future<RideEntity> createRide(RideEntity ride);
  Future<void> deleteRide(int id);
}
