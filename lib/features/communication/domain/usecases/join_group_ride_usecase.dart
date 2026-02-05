import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/group_ride_repository.dart';

/// Grup turuna katılma use case
class JoinGroupRideUseCase {
  final GroupRideRepository repository;

  JoinGroupRideUseCase(this.repository);

  Future<Either<Failure, void>> call(int rideId, {String? joinMessage}) {
    return repository.joinGroupRide(rideId, joinMessage: joinMessage);
  }
}
