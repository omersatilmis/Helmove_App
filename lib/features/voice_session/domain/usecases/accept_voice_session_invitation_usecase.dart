import '../repositories/voice_session_repository.dart';

class AcceptVoiceSessionInvitationUseCase {
  final VoiceSessionRepository repository;

  AcceptVoiceSessionInvitationUseCase(this.repository);

  Future<void> call(int id) async {
    return await repository.acceptInvitation(id);
  }
}
