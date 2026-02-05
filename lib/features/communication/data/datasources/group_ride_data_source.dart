import '../api/group_ride_api.dart';
import '../models/group_ride_model.dart';
import '../models/group_ride_participant_model.dart';

/// GroupRide Data Source arayüzü
abstract class GroupRideDataSource {
  Future<GroupRideModel> createGroupRide(Map<String, dynamic> data);
  Future<GroupRideModel> updateGroupRide(int id, Map<String, dynamic> data);
  Future<GroupRideModel> getGroupRideById(int id);
  Future<List<GroupRideModel>> getActiveGroupRides();
  Future<List<GroupRideModel>> getMyRides();
  Future<List<GroupRideModel>> getNearbyGroupRides(
    double latitude,
    double longitude, {
    double radiusKm = 50,
  });
  Future<void> joinGroupRide(int rideId, {String? joinMessage});
  Future<void> leaveGroupRide(int rideId);
  Future<List<GroupRideParticipantModel>> getParticipants(int rideId);
  Future<void> startGroupRide(int rideId);
  Future<void> completeGroupRide(int rideId);
  Future<void> deleteGroupRide(int rideId);
}

/// GroupRide Data Source implementasyonu
class GroupRideDataSourceImpl implements GroupRideDataSource {
  final GroupRideApi _api;

  GroupRideDataSourceImpl(this._api);

  @override
  Future<GroupRideModel> createGroupRide(Map<String, dynamic> data) {
    return _api.createGroupRide(data);
  }

  @override
  Future<GroupRideModel> updateGroupRide(int id, Map<String, dynamic> data) {
    return _api.updateGroupRide(id, data);
  }

  @override
  Future<GroupRideModel> getGroupRideById(int id) {
    return _api.getGroupRideById(id);
  }

  @override
  Future<List<GroupRideModel>> getActiveGroupRides() {
    return _api.getActiveGroupRides();
  }

  @override
  Future<List<GroupRideModel>> getMyRides() {
    return _api.getMyRides();
  }

  @override
  Future<List<GroupRideModel>> getNearbyGroupRides(
    double latitude,
    double longitude, {
    double radiusKm = 50,
  }) {
    return _api.getNearbyGroupRides(latitude, longitude, radiusKm: radiusKm);
  }

  @override
  Future<void> joinGroupRide(int rideId, {String? joinMessage}) {
    return _api.joinGroupRide(rideId, joinMessage: joinMessage);
  }

  @override
  Future<void> leaveGroupRide(int rideId) {
    return _api.leaveGroupRide(rideId);
  }

  @override
  Future<List<GroupRideParticipantModel>> getParticipants(int rideId) {
    return _api.getParticipants(rideId);
  }

  @override
  Future<void> startGroupRide(int rideId) {
    return _api.startGroupRide(rideId);
  }

  @override
  Future<void> completeGroupRide(int rideId) {
    return _api.completeGroupRide(rideId);
  }

  @override
  Future<void> deleteGroupRide(int rideId) {
    return _api.deleteGroupRide(rideId);
  }
}
