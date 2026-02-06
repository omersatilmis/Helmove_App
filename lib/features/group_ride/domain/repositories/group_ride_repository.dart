import '../entities/group_ride_entity.dart';

abstract class GroupRideRepository {
  Future<GroupRideEntity> createGroupRide(GroupRideEntity ride);
  Future<List<GroupRideEntity>> getActiveGroupRides();
  Future<GroupRideEntity> getGroupRideById(int rideId);
  Future<GroupRideEntity> updateGroupRide(int rideId, GroupRideEntity ride);
  Future<bool> deleteGroupRide(int rideId);
}
