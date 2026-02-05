import '../repositories/voice_session_repository.dart';

class LeaveVoiceSessionUseCase {
  final VoiceSessionRepository repository;

  LeaveVoiceSessionUseCase(this.repository);

  Future<void> call(int id) async {
    return await repository.leaveSession(id);
  }
}
