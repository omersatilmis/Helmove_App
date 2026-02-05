import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/group_ride_entity.dart';
import '../entities/group_ride_participant_entity.dart';

/// GroupRide Repository arayüzü
abstract class GroupRideRepository {
  Future<Either<Failure, GroupRideEntity>> createGroupRide(
    Map<String, dynamic> data,
  );
  Future<Either<Failure, GroupRideEntity>> updateGroupRide(
    int id,
    Map<String, dynamic> data,
  );
  Future<Either<Failure, GroupRideEntity>> getGroupRideById(int id);
  Future<Either<Failure, List<GroupRideEntity>>> getActiveGroupRides();
  Future<Either<Failure, List<GroupRideEntity>>> getMyRides();
  Future<Either<Failure, List<GroupRideEntity>>> getNearbyGroupRides(
    double latitude,
    double longitude, {
    double radiusKm = 50,
  });
  Future<Either<Failure, void>> joinGroupRide(
    int rideId, {
    String? joinMessage,
  });
  Future<Either<Failure, void>> leaveGroupRide(int rideId);
  Future<Either<Failure, List<GroupRideParticipantEntity>>> getParticipants(
    int rideId,
  );
  Future<Either<Failure, void>> startGroupRide(int rideId);
  Future<Either<Failure, void>> completeGroupRide(int rideId);
  Future<Either<Failure, void>> deleteGroupRide(int rideId);
}
