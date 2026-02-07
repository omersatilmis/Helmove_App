import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/attendance_repository.dart';

class RejectParticipantUseCase {
  final AttendanceRepository repository;

  RejectParticipantUseCase(this.repository);

  Future<Either<Failure, Unit>> call(int rideId, int userId) async {
    return await repository.rejectParticipant(rideId, userId);
  }
}
