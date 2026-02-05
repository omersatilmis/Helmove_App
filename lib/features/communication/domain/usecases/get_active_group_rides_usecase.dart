import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/group_ride_entity.dart';
import '../repositories/group_ride_repository.dart';

class GetActiveGroupRidesUseCase {
  final GroupRideRepository repository;

  GetActiveGroupRidesUseCase(this.repository);

  Future<Either<Failure, List<GroupRideEntity>>> call() {
    return repository.getActiveGroupRides();
  }
}
