import '../../domain/entities/group_ride_entity.dart';
import '../../domain/repositories/group_ride_repository.dart';
import '../datasources/group_ride_remote_data_source.dart';
import '../models/group_ride_model.dart';

class GroupRideRepositoryImpl implements GroupRideRepository {
  final GroupRideRemoteDataSource remoteDataSource;

  GroupRideRepositoryImpl(this.remoteDataSource);

  @override
  Future<GroupRideEntity> createGroupRide(GroupRideEntity ride) async {
    final model = GroupRideModel(
      id: ride.id,
      title: ride.title,
      description: ride.description,
      organizerId: ride.organizerId,
      startDateTime: ride.startDateTime,
      endDateTime: ride.endDateTime,
      startLocation: ride.startLocation,
      startLatitude: ride.startLatitude,
      startLongitude: ride.startLongitude,
      endLocation: ride.endLocation,
      endLatitude: ride.endLatitude,
      endLongitude: ride.endLongitude,
      maxParticipants: ride.maxParticipants,
      estimatedDistanceKm: ride.estimatedDistanceKm,
      estimatedDurationMinutes: ride.estimatedDurationMinutes,
      status: ride.status,
      difficulty: ride.difficulty,
      requirements: ride.requirements,
    );
    return await remoteDataSource.createGroupRide(model);
  }

  @override
  Future<List<GroupRideEntity>> getActiveGroupRides() async {
    return await remoteDataSource.getActiveGroupRides();
  }

  @override
  Future<GroupRideEntity> getGroupRideById(int rideId) async {
    return await remoteDataSource.getGroupRideById(rideId);
  }

  @override
  Future<GroupRideEntity> updateGroupRide(
    int rideId,
    GroupRideEntity ride,
  ) async {
    final model = GroupRideModel(
      id: ride.id,
      title: ride.title,
      description: ride.description,
      organizerId: ride.organizerId,
      startDateTime: ride.startDateTime,
      endDateTime: ride.endDateTime,
      startLocation: ride.startLocation,
      startLatitude: ride.startLatitude,
      startLongitude: ride.startLongitude,
      endLocation: ride.endLocation,
      endLatitude: ride.endLatitude,
      endLongitude: ride.endLongitude,
      maxParticipants: ride.maxParticipants,
      estimatedDistanceKm: ride.estimatedDistanceKm,
      estimatedDurationMinutes: ride.estimatedDurationMinutes,
      status: ride.status,
      difficulty: ride.difficulty,
      requirements: ride.requirements,
    );
    return await remoteDataSource.updateGroupRide(rideId, model);
  }

  @override
  Future<bool> deleteGroupRide(int rideId) async {
    return await remoteDataSource.deleteGroupRide(rideId);
  }
}
