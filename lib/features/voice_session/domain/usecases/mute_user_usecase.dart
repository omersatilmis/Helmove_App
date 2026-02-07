import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/voice_session_repository.dart';

class MuteUserUseCase {
  final VoiceSessionRepository repository;

  MuteUserUseCase(this.repository);

  Future<Either<Failure, Unit>> call(int sessionId, int targetUserId) async {
    return await repository.muteUser(sessionId, targetUserId);
  }
}
