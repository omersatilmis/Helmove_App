import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/group_ride_participant_entity.dart';
import '../repositories/group_ride_repository.dart';

/// Grup turu katılımcılarını getiren use case
class GetGroupRideParticipantsUseCase {
  final GroupRideRepository repository;

  GetGroupRideParticipantsUseCase(this.repository);

  Future<Either<Failure, List<GroupRideParticipantEntity>>> call(int rideId) {
    return repository.getParticipants(rideId);
  }
}
