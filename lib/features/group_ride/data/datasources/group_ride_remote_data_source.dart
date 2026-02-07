import '../models/group_ride_model.dart';

abstract class GroupRideRemoteDataSource {
  Future<GroupRideModel> createGroupRide(GroupRideModel ride);
  Future<List<GroupRideModel>> getActiveGroupRides();
  Future<GroupRideModel> getGroupRideById(int rideId);
  Future<GroupRideModel> updateGroupRide(int rideId, GroupRideModel ride);
  Future<bool> deleteGroupRide(int rideId);
}

class GroupRideRemoteDataSourceImpl implements GroupRideRemoteDataSource {
  final GroupRideRemoteDataSource
  _api; // Assuming the API class acts as the data source for now or acts as the client

  GroupRideRemoteDataSourceImpl(this._api);

  @override
  Future<GroupRideModel> createGroupRide(GroupRideModel ride) async {
    return await _api.createGroupRide(ride);
  }

  @override
  Future<List<GroupRideModel>> getActiveGroupRides() async {
    return await _api.getActiveGroupRides();
  }

  @override
  Future<GroupRideModel> getGroupRideById(int rideId) async {
    return await _api.getGroupRideById(rideId);
  }

  @override
  Future<GroupRideModel> updateGroupRide(
    int rideId,
    GroupRideModel ride,
  ) async {
    return await _api.updateGroupRide(rideId, ride);
  }

  @override
  Future<bool> deleteGroupRide(int rideId) async {
    return await _api.deleteGroupRide(rideId);
  }
}
