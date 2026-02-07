import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/participant_entity.dart';
import '../repositories/attendance_repository.dart';

class GetRideParticipantsUseCase {
  final AttendanceRepository repository;

  GetRideParticipantsUseCase(this.repository);

  Future<Either<Failure, List<ParticipantEntity>>> call(int rideId) async {
    return await repository.getRideParticipants(rideId);
  }
}
