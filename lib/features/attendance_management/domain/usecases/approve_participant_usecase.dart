import '../repositories/attendance_repository.dart';

class ApproveParticipantUseCase {
  final AttendanceRepository repository;

  ApproveParticipantUseCase(this.repository);

  Future<void> call(int rideId, int userId) async {
    return await repository.approveParticipant(rideId, userId);
  }
}
