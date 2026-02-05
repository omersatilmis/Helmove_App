import '../repositories/attendance_repository.dart';

class JoinGroupRideUseCase {
  final AttendanceRepository repository;

  JoinGroupRideUseCase(this.repository);

  Future<void> call(int rideId, {String? joinMessage}) async {
    return await repository.joinGroupRide(rideId, joinMessage: joinMessage);
  }
}
