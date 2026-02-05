import '../repositories/attendance_repository.dart';

class GetRideParticipantsUseCase {
  final AttendanceRepository repository;

  GetRideParticipantsUseCase(this.repository);

  Future<List<dynamic>> call(int rideId) async {
    return await repository.getRideParticipants(rideId);
  }
}
