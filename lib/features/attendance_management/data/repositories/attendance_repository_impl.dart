import '../../domain/repositories/attendance_repository.dart';
import '../datasources/attendance_remote_data_source.dart';

class AttendanceRepositoryImpl implements AttendanceRepository {
  final AttendanceRemoteDataSource remoteDataSource;

  AttendanceRepositoryImpl(this.remoteDataSource);

  @override
  Future<void> joinGroupRide(int rideId, {String? joinMessage}) async {
    return await remoteDataSource.joinGroupRide(
      rideId,
      joinMessage: joinMessage,
    );
  }

  @override
  Future<void> leaveGroupRide(int rideId) async {
    return await remoteDataSource.leaveGroupRide(rideId);
  }

  @override
  Future<void> approveParticipant(int rideId, int userId) async {
    return await remoteDataSource.approveParticipant(rideId, userId);
  }

  @override
  Future<void> rejectParticipant(int rideId, int userId) async {
    return await remoteDataSource.rejectParticipant(rideId, userId);
  }

  @override
  Future<List<dynamic>> getRideParticipants(int rideId) async {
    return await remoteDataSource.getRideParticipants(rideId);
  }

  @override
  Future<dynamic> getParticipationStatus(int rideId) async {
    return await remoteDataSource.getParticipationStatus(rideId);
  }
}
