import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/group_ride_summary.dart';
import '../repositories/group_ride_repository.dart';

class GetNearbyGroupRidesParams {
  final double latitude;
  final double longitude;
  final double radiusKm;

  const GetNearbyGroupRidesParams({
    required this.latitude,
    required this.longitude,
    this.radiusKm = 50,
  });
}

class GetNearbyGroupRidesUseCase {
  final GroupRideRepository repository;

  GetNearbyGroupRidesUseCase(this.repository);

  Future<Either<Failure, List<GroupRideSummary>>> execute(
    GetNearbyGroupRidesParams params,
  ) async {
    return await repository.getNearbyGroupRides(
      latitude: params.latitude,
      longitude: params.longitude,
      radiusKm: params.radiusKm,
    );
  }
}
