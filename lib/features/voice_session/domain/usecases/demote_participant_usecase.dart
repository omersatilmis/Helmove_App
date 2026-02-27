import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/voice_session_repository.dart';

class DemoteParticipantUseCase {
  final VoiceSessionRepository repository;

  DemoteParticipantUseCase(this.repository);

  Future<Either<Failure, Unit>> call(int sessionId, int targetUserId) async {
    return await repository.demoteParticipant(sessionId, targetUserId);
  }
}
