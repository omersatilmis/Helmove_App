import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/attendance_repository.dart';

class ApproveParticipantUseCase {
  final AttendanceRepository repository;

  ApproveParticipantUseCase(this.repository);

  Future<Either<Failure, Unit>> call(int rideId, int userId) async {
    return await repository.approveParticipant(rideId, userId);
  }
}
