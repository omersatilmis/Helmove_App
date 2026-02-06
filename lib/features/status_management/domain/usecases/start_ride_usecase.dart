import '../repositories/status_repository.dart';

class StartRideUseCase {
  final StatusRepository repository;

  StartRideUseCase(this.repository);

  Future<void> execute(int rideId) async {
    return await repository.startRide(rideId);
  }
}
