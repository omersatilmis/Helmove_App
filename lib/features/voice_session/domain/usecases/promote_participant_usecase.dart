import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/voice_session_repository.dart';

class PromoteParticipantUseCase {
  final VoiceSessionRepository repository;

  PromoteParticipantUseCase(this.repository);

  Future<Either<Failure, Unit>> call(int rideId, int targetUserId) async {
    return await repository.promoteParticipant(rideId, targetUserId);
  }
}
