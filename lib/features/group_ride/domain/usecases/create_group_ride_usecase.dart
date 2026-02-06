import '../entities/group_ride_entity.dart';
import '../repositories/group_ride_repository.dart';

class CreateGroupRideUseCase {
  final GroupRideRepository repository;

  CreateGroupRideUseCase(this.repository);

  Future<GroupRideEntity> execute(GroupRideEntity ride) async {
    return await repository.createGroupRide(ride);
  }
}
