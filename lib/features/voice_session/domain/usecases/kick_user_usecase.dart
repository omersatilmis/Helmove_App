import '../repositories/voice_session_repository.dart';

class KickUserUseCase {
  final VoiceSessionRepository repository;

  KickUserUseCase(this.repository);

  Future<void> call(int sessionId, int targetUserId) async {
    return await repository.kickUser(sessionId, targetUserId);
  }
}
