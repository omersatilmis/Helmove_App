import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/group_ride_entity.dart';

abstract class GroupRideRepository {
  Future<Either<Failure, GroupRideEntity>> createGroupRide(
    GroupRideEntity ride,
  );
  Future<Either<Failure, List<GroupRideEntity>>> getActiveGroupRides();
  Future<Either<Failure, GroupRideEntity>> getGroupRideById(int rideId);
  Future<Either<Failure, GroupRideEntity>> updateGroupRide(
    int rideId,
    GroupRideEntity ride,
  );
  Future<Either<Failure, bool>> deleteGroupRide(int rideId);
}
