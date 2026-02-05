import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/group_ride_repository.dart';

/// Grup turundan ayrılma use case
class LeaveGroupRideUseCase {
  final GroupRideRepository repository;

  LeaveGroupRideUseCase(this.repository);

  Future<Either<Failure, void>> call(int rideId) {
    return repository.leaveGroupRide(rideId);
  }
}
