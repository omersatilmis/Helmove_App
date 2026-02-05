import '../repositories/voice_session_repository.dart';

class JoinVoiceSessionUseCase {
  final VoiceSessionRepository repository;

  JoinVoiceSessionUseCase(this.repository);

  Future<void> call(int id) async {
    return await repository.joinSession(id);
  }
}
