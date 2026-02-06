import '../api/status_api.dart';

abstract class StatusRemoteDataSource {
  Future<void> startRide(int rideId);
  Future<void> completeRide(int rideId);
  Future<void> cancelRide(int rideId);
  Future<void> postponeRide(int rideId, DateTime newDateTime);
}

class StatusRemoteDataSourceImpl implements StatusRemoteDataSource {
  final StatusApi api;

  StatusRemoteDataSourceImpl(this.api);

  @override
  Future<void> startRide(int rideId) async {
    return await api.startRide(rideId);
  }

  @override
  Future<void> completeRide(int rideId) async {
    return await api.completeRide(rideId);
  }

  @override
  Future<void> cancelRide(int rideId) async {
    return await api.cancelRide(rideId);
  }

  @override
  Future<void> postponeRide(int rideId, DateTime newDateTime) async {
    return await api.postponeRide(rideId, newDateTime);
  }
}
