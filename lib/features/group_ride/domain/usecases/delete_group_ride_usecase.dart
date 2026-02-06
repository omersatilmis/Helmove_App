import '../repositories/group_ride_repository.dart';

class DeleteGroupRideUseCase {
  final GroupRideRepository repository;

  DeleteGroupRideUseCase(this.repository);

  Future<bool> execute(int rideId) async {
    return await repository.deleteGroupRide(rideId);
  }
}
