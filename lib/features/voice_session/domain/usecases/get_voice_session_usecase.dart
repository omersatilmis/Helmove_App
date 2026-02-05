import '../repositories/voice_session_repository.dart';

class GetVoiceSessionUseCase {
  final VoiceSessionRepository repository;

  GetVoiceSessionUseCase(this.repository);

  Future<dynamic> call(int id) async {
    return await repository.getSession(id);
  }
}
