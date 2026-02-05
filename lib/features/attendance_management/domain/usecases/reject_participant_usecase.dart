import '../repositories/attendance_repository.dart';

class RejectParticipantUseCase {
  final AttendanceRepository repository;

  RejectParticipantUseCase(this.repository);

  Future<void> call(int rideId, int userId) async {
    return await repository.rejectParticipant(rideId, userId);
  }
}
