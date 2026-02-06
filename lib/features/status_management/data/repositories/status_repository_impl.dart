import '../../domain/repositories/status_repository.dart';
import '../datasources/status_remote_data_source.dart';

class StatusRepositoryImpl implements StatusRepository {
  final StatusRemoteDataSource remoteDataSource;

  StatusRepositoryImpl(this.remoteDataSource);

  @override
  Future<void> startRide(int rideId) async {
    return await remoteDataSource.startRide(rideId);
  }

  @override
  Future<void> completeRide(int rideId) async {
    return await remoteDataSource.completeRide(rideId);
  }

  @override
  Future<void> cancelRide(int rideId) async {
    return await remoteDataSource.cancelRide(rideId);
  }

  @override
  Future<void> postponeRide(int rideId, DateTime newDateTime) async {
    return await remoteDataSource.postponeRide(rideId, newDateTime);
  }
}
