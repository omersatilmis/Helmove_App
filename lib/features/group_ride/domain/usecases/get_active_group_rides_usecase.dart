import '../entities/group_ride_entity.dart';
import '../repositories/group_ride_repository.dart';

class GetActiveGroupRidesUseCase {
  final GroupRideRepository repository;

  GetActiveGroupRidesUseCase(this.repository);

  Future<List<GroupRideEntity>> execute() async {
    return await repository.getActiveGroupRides();
  }
}
