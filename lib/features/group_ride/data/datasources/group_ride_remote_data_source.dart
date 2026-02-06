import '../api/group_ride_api.dart';
import '../models/group_ride_model.dart';

abstract class GroupRideRemoteDataSource {
  Future<GroupRideModel> createGroupRide(GroupRideModel ride);
  Future<List<GroupRideModel>> getActiveGroupRides();
  Future<GroupRideModel> getGroupRideById(int rideId);
  Future<GroupRideModel> updateGroupRide(int rideId, GroupRideModel ride);
  Future<bool> deleteGroupRide(int rideId);
}

class GroupRideRemoteDataSourceImpl implements GroupRideRemoteDataSource {
  final GroupRideApi api;

  GroupRideRemoteDataSourceImpl(this.api);

  @override
  Future<GroupRideModel> createGroupRide(GroupRideModel ride) async {
    return await api.createGroupRide(ride);
  }

  @override
  Future<List<GroupRideModel>> getActiveGroupRides() async {
    return await api.getActiveGroupRides();
  }

  @override
  Future<GroupRideModel> getGroupRideById(int rideId) async {
    return await api.getGroupRideById(rideId);
  }

  @override
  Future<GroupRideModel> updateGroupRide(
    int rideId,
    GroupRideModel ride,
  ) async {
    return await api.updateGroupRide(rideId, ride);
  }

  @override
  Future<bool> deleteGroupRide(int rideId) async {
    return await api.deleteGroupRide(rideId);
  }
}
