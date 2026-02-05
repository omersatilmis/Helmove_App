import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/group_ride_repository.dart';

class DeleteGroupRideUseCase {
  final GroupRideRepository repository;

  DeleteGroupRideUseCase(this.repository);

  Future<Either<Failure, void>> call(int id) {
    return repository.deleteGroupRide(id);
  }
}
