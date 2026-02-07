import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/attendance_repository.dart';

class JoinGroupRideUseCase {
  final AttendanceRepository repository;

  JoinGroupRideUseCase(this.repository);

  Future<Either<Failure, Unit>> call(int rideId, {String? joinMessage}) async {
    return await repository.joinGroupRide(rideId, joinMessage: joinMessage);
  }
}
