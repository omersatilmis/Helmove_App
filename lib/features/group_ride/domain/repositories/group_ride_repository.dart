import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/group_ride_entity.dart';
import '../entities/group_ride_summary.dart';
import '../entities/group_ride_search_result.dart';
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

  /// Keşfet araması (çoklu kriter, sayfalı).
  Future<Either<Failure, GroupRideSearchResult>> searchGroupRides({
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

  /// Yakındaki turlar (distanceKm dolu döner).
  Future<Either<Failure, List<GroupRideSummary>>> getNearbyGroupRides({
    required double latitude,
    required double longitude,
    double radiusKm,
  });
}
