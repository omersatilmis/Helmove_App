import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/group_ride_entity.dart';
import '../repositories/group_ride_repository.dart';

/// Kullanıcının grup turlarını getiren use case
class GetMyGroupRidesUseCase {
  final GroupRideRepository repository;

  GetMyGroupRidesUseCase(this.repository);

  Future<Either<Failure, List<GroupRideEntity>>> call() {
    return repository.getMyRides();
  }
}
