import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/group_ride_entity.dart';
import '../repositories/group_ride_repository.dart';
import '../../data/dto/create_group_ride_request_dto.dart';

class CreateGroupRideUseCase {
  final GroupRideRepository repository;

  CreateGroupRideUseCase(this.repository);

  Future<Either<Failure, GroupRideEntity>> execute(
    CreateGroupRideRequestDto request,
  ) async {
    return await repository.createGroupRide(request);
  }
}
