import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/group_ride_repository.dart';

class DeleteGroupRideUseCase {
  final GroupRideRepository repository;

  DeleteGroupRideUseCase(this.repository);

  Future<Either<Failure, bool>> execute(int rideId) async {
    return await repository.deleteGroupRide(rideId);
  }
}
