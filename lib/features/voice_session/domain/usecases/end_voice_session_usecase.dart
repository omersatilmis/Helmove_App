import '../repositories/voice_session_repository.dart';

class EndVoiceSessionUseCase {
  final VoiceSessionRepository repository;

  EndVoiceSessionUseCase(this.repository);

  Future<void> call(int id) async {
    return await repository.endSession(id);
  }
}
