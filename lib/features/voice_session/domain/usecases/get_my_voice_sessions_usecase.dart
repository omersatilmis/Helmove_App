import '../entities/voice_session_entity.dart';
import '../repositories/voice_session_repository.dart';

/// Kullanıcının aktif voice session'larını getiren use case
class GetMyVoiceSessionsUseCase {
  final VoiceSessionRepository repository;

  GetMyVoiceSessionsUseCase(this.repository);

  Future<List<VoiceSessionEntity>> call() async {
    return await repository.getMySessions();
  }
}
