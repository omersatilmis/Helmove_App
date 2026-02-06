abstract class StatusRepository {
  Future<void> startRide(int rideId);
  Future<void> completeRide(int rideId);
  Future<void> cancelRide(int rideId);
  Future<void> postponeRide(int rideId, DateTime newDateTime);
}
