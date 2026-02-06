import '../entities/group_ride_entity.dart';
import '../repositories/group_ride_repository.dart';

class UpdateGroupRideUseCase {
  final GroupRideRepository repository;

  UpdateGroupRideUseCase(this.repository);

  Future<GroupRideEntity> execute(int rideId, GroupRideEntity ride) async {
    return await repository.updateGroupRide(rideId, ride);
  }
}
