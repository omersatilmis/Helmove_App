import '../api/attendance_api.dart';

abstract class AttendanceRemoteDataSource {
  Future<void> joinGroupRide(int rideId, {String? joinMessage});
  Future<void> leaveGroupRide(int rideId);
  Future<void> approveParticipant(int rideId, int userId);
  Future<void> rejectParticipant(int rideId, int userId);
  Future<List<dynamic>> getRideParticipants(int rideId);
  Future<dynamic> getParticipationStatus(int rideId);
}

class AttendanceRemoteDataSourceImpl implements AttendanceRemoteDataSource {
  final AttendanceApi api;

  AttendanceRemoteDataSourceImpl(this.api);

  @override
  Future<void> joinGroupRide(int rideId, {String? joinMessage}) async {
    return await api.joinGroupRide(rideId, joinMessage: joinMessage);
  }

  @override
  Future<void> leaveGroupRide(int rideId) async {
    return await api.leaveGroupRide(rideId);
  }

  @override
  Future<void> approveParticipant(int rideId, int userId) async {
    return await api.approveParticipant(rideId, userId);
  }

  @override
  Future<void> rejectParticipant(int rideId, int userId) async {
    return await api.rejectParticipant(rideId, userId);
  }

  @override
  Future<List<dynamic>> getRideParticipants(int rideId) async {
    return await api.getRideParticipants(rideId);
  }

  @override
  Future<dynamic> getParticipationStatus(int rideId) async {
    return await api.getParticipationStatus(rideId);
  }
}
