import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/voice_session_repository.dart';

class KickUserUseCase {
  final VoiceSessionRepository repository;

  KickUserUseCase(this.repository);

  Future<Either<Failure, Unit>> call(int sessionId, int targetUserId) async {
    return await repository.kickUser(sessionId, targetUserId);
  }
}
