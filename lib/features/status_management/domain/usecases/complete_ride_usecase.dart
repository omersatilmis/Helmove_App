import '../repositories/status_repository.dart';

class CompleteRideUseCase {
  final StatusRepository repository;

  CompleteRideUseCase(this.repository);

  Future<void> execute(int rideId) async {
    return await repository.completeRide(rideId);
  }
}
