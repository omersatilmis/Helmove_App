import '../repositories/status_repository.dart';

class CancelRideUseCase {
  final StatusRepository repository;

  CancelRideUseCase(this.repository);

  Future<void> execute(int rideId) async {
    return await repository.cancelRide(rideId);
  }
}
