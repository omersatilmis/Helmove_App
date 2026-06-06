import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/group_ride_entity.dart';
import '../../domain/repositories/group_ride_repository.dart';
import '../datasources/group_ride_remote_data_source.dart';
import '../dto/create_group_ride_request_dto.dart';
import '../models/group_ride_model.dart';

class GroupRideRepositoryImpl implements GroupRideRepository {
  final GroupRideRemoteDataSource remoteDataSource;

  GroupRideRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, GroupRideEntity>> createGroupRide(
    CreateGroupRideRequestDto request,
  ) async {
    try {
      final result = await remoteDataSource.createGroupRide(request);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<GroupRideEntity>>> getActiveGroupRides() async {
    try {
      final result = await remoteDataSource.getActiveGroupRides();
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, GroupRideEntity>> getGroupRideById(int rideId) async {
    try {
      final result = await remoteDataSource.getGroupRideById(rideId);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, GroupRideEntity>> updateGroupRide(
    int rideId,
    GroupRideEntity ride,
  ) async {
    try {
      final model = _mapToModel(ride);
      final result = await remoteDataSource.updateGroupRide(rideId, model);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> deleteGroupRide(int rideId) async {
    try {
      final result = await remoteDataSource.deleteGroupRide(rideId);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  GroupRideModel _mapToModel(GroupRideEntity ride) {
    return GroupRideModel(
      id: ride.id,
      title: ride.title,
      description: ride.description,
      adminId: ride.adminId,
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
      ridingStyle: ride.ridingStyle,
      requirements: ride.requirements,
      isPrivate: ride.isPrivate,
      sessionId: ride.sessionId,
      routeGeometry: ride.routeGeometry,
      routeProfile: ride.routeProfile,
      routeDistanceMeters: ride.routeDistanceMeters,
      routeDurationSeconds: ride.routeDurationSeconds,
    );
  }
}
