import '../models/participant_model.dart';
import '../models/participation_status_model.dart';

abstract class AttendanceRemoteDataSource {
  Future<void> joinGroupRide(int rideId, {String? joinMessage});
  Future<void> leaveGroupRide(int rideId);
  Future<void> approveParticipant(int rideId, int userId);
  Future<void> rejectParticipant(int rideId, int userId);
  Future<List<ParticipantModel>> getRideParticipants(int rideId);
  Future<ParticipationStatusModel> getParticipationStatus(int rideId);
}

class AttendanceRemoteDataSourceImpl implements AttendanceRemoteDataSource {
  final AttendanceRemoteDataSource _api;

  AttendanceRemoteDataSourceImpl(this._api);

  @override
  Future<void> joinGroupRide(int rideId, {String? joinMessage}) async {
    return await _api.joinGroupRide(rideId, joinMessage: joinMessage);
  }

  @override
  Future<void> leaveGroupRide(int rideId) async {
    return await _api.leaveGroupRide(rideId);
  }

  @override
  Future<void> approveParticipant(int rideId, int userId) async {
    return await _api.approveParticipant(rideId, userId);
  }

  @override
  Future<void> rejectParticipant(int rideId, int userId) async {
    return await _api.rejectParticipant(rideId, userId);
  }

  @override
  Future<List<ParticipantModel>> getRideParticipants(int rideId) async {
    return await _api.getRideParticipants(rideId);
  }

  @override
  Future<ParticipationStatusModel> getParticipationStatus(int rideId) async {
    return await _api.getParticipationStatus(rideId);
  }
}
