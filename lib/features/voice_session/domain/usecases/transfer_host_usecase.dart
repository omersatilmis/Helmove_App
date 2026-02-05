import '../repositories/voice_session_repository.dart';

class TransferHostUseCase {
  final VoiceSessionRepository repository;

  TransferHostUseCase(this.repository);

  Future<void> call(int sessionId, int newHostId) async {
    return await repository.transferHost(sessionId, newHostId);
  }
}
