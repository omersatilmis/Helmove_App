import '../repositories/attendance_repository.dart';

class LeaveGroupRideUseCase {
  final AttendanceRepository repository;

  LeaveGroupRideUseCase(this.repository);

  Future<void> call(int rideId) async {
    return await repository.leaveGroupRide(rideId);
  }
}
