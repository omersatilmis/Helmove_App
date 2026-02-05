import '../repositories/voice_session_repository.dart';

class MuteUserUseCase {
  final VoiceSessionRepository repository;

  MuteUserUseCase(this.repository);

  Future<void> call(int sessionId, int targetUserId) async {
    return await repository.muteUser(sessionId, targetUserId);
  }
}
