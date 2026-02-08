import '../api/group_ride_api.dart';
import '../models/group_ride_model.dart';
import '../dto/create_group_ride_request_dto.dart';

abstract class GroupRideRemoteDataSource {
  Future<GroupRideModel> createGroupRide(CreateGroupRideRequestDto request);
  Future<List<GroupRideModel>> getActiveGroupRides();
  Future<GroupRideModel> getGroupRideById(int rideId);
  Future<GroupRideModel> updateGroupRide(int rideId, GroupRideModel ride);
  Future<bool> deleteGroupRide(int rideId);
}

class GroupRideRemoteDataSourceImpl implements GroupRideRemoteDataSource {
  final GroupRideApi
  _api; // Assuming the API class acts as the data source for now or acts as the client

  GroupRideRemoteDataSourceImpl(this._api);

  @override
  Future<GroupRideModel> createGroupRide(
    CreateGroupRideRequestDto request,
  ) async {
    return await _api.createGroupRide(request);
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
