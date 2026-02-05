import '../repositories/attendance_repository.dart';

class GetParticipationStatusUseCase {
  final AttendanceRepository repository;

  GetParticipationStatusUseCase(this.repository);

  Future<dynamic> call(int rideId) async {
    return await repository.getParticipationStatus(rideId);
  }
}
