import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import 'package:moto_comm_app_1/features/attendance_management/domain/repositories/attendance_repository.dart';

class LeaveGroupRideUseCase {
  final AttendanceRepository repository;

  LeaveGroupRideUseCase(this.repository);

  Future<Either<Failure, Unit>> call(int rideId) async {
    return await repository.leaveGroupRide(rideId);
  }
}
