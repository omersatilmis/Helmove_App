import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/group_ride_entity.dart';
import '../repositories/group_ride_repository.dart';

/// Yeni grup turu oluşturan use case
class CreateGroupRideUseCase {
  final GroupRideRepository repository;

  CreateGroupRideUseCase(this.repository);

  Future<Either<Failure, GroupRideEntity>> call(Map<String, dynamic> data) {
    return repository.createGroupRide(data);
  }
}
