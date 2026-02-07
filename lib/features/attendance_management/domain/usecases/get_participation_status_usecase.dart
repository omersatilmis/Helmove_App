import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/participation_status_entity.dart';
import '../repositories/attendance_repository.dart';

class GetParticipationStatusUseCase {
  final AttendanceRepository repository;

  GetParticipationStatusUseCase(this.repository);

  Future<Either<Failure, ParticipationStatusEntity>> call(int rideId) async {
    return await repository.getParticipationStatus(rideId);
  }
}
