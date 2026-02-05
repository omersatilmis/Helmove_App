import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/group_ride_entity.dart';
import '../repositories/group_ride_repository.dart';

/// Yakındaki grup turlarını getiren use case
class GetNearbyGroupRidesUseCase {
  final GroupRideRepository repository;

  GetNearbyGroupRidesUseCase(this.repository);

  Future<Either<Failure, List<GroupRideEntity>>> call({
    required double latitude,
    required double longitude,
    double radiusKm = 50,
  }) {
    return repository.getNearbyGroupRides(
      latitude,
      longitude,
      radiusKm: radiusKm,
    );
  }
}
