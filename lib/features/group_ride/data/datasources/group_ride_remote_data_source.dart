import '../api/group_ride_api.dart';
import '../models/group_ride_model.dart';
import '../models/group_ride_summary_model.dart';
import '../dto/create_group_ride_request_dto.dart';
import '../../domain/entities/group_ride_search_result.dart';

abstract class GroupRideRemoteDataSource {
  Future<GroupRideModel> createGroupRide(CreateGroupRideRequestDto request);
  Future<List<GroupRideModel>> getActiveGroupRides();
  Future<GroupRideModel> getGroupRideById(int rideId);
  Future<GroupRideModel> updateGroupRide(int rideId, GroupRideModel ride);
  Future<bool> deleteGroupRide(int rideId);
  Future<GroupRideSearchResult> searchGroupRides({
    String? title,
    String? location,
    String? difficulty,
    String? ridingStyle,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    int page,
    int pageSize,
  });
  Future<List<GroupRideSummaryModel>> getNearbyGroupRides({
    required double latitude,
    required double longitude,
    double radiusKm,
  });
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

  @override
  Future<GroupRideSearchResult> searchGroupRides({
    String? title,
    String? location,
    String? difficulty,
    String? ridingStyle,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    int page = 1,
    int pageSize = 20,
  }) async {
    return await _api.searchGroupRides(
      title: title,
      location: location,
      difficulty: difficulty,
      ridingStyle: ridingStyle,
      status: status,
      startDate: startDate,
      endDate: endDate,
      page: page,
      pageSize: pageSize,
    );
  }

  @override
  Future<List<GroupRideSummaryModel>> getNearbyGroupRides({
    required double latitude,
    required double longitude,
    double radiusKm = 50,
  }) async {
    return await _api.getNearbyGroupRides(
      latitude: latitude,
      longitude: longitude,
      radiusKm: radiusKm,
    );
  }
}
