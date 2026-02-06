import '../repositories/status_repository.dart';

class PostponeRideUseCase {
  final StatusRepository repository;

  PostponeRideUseCase(this.repository);

  Future<void> execute(int rideId, DateTime newDateTime) async {
    return await repository.postponeRide(rideId, newDateTime);
  }
}
