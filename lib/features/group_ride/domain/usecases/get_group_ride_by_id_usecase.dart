import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/group_ride_entity.dart';
import '../repositories/group_ride_repository.dart';

class GetGroupRideByIdUseCase {
  final GroupRideRepository repository;

  GetGroupRideByIdUseCase(this.repository);

  Future<Either<Failure, GroupRideEntity>> execute(int rideId) async {
    return await repository.getGroupRideById(rideId);
  }
}
