import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/group_ride_entity.dart';
import '../../data/dto/create_group_ride_request_dto.dart';

abstract class GroupRideRepository {
  Future<Either<Failure, GroupRideEntity>> createGroupRide(
    CreateGroupRideRequestDto request,
  );
  Future<Either<Failure, List<GroupRideEntity>>> getActiveGroupRides();
  Future<Either<Failure, GroupRideEntity>> getGroupRideById(int rideId);
  Future<Either<Failure, GroupRideEntity>> updateGroupRide(
    int rideId,
    GroupRideEntity ride,
  );
  Future<Either<Failure, bool>> deleteGroupRide(int rideId);
}
