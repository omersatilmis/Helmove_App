import '../entities/voice_session_entity.dart';
import '../repositories/voice_session_repository.dart';

/// Tek bir voice session'ın detaylarını getiren use case
class GetVoiceSessionDetailsUseCase {
  final VoiceSessionRepository repository;

  GetVoiceSessionDetailsUseCase(this.repository);

  Future<VoiceSessionEntity> call(int sessionId) async {
    return await repository.getSession(sessionId);
  }
}
