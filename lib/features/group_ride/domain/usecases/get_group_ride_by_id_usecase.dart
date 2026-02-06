import '../entities/group_ride_entity.dart';
import '../repositories/group_ride_repository.dart';

class GetGroupRideByIdUseCase {
  final GroupRideRepository repository;

  GetGroupRideByIdUseCase(this.repository);

  Future<GroupRideEntity> execute(int rideId) async {
    return await repository.getGroupRideById(rideId);
  }
}
