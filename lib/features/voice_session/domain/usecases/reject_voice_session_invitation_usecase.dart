import '../repositories/voice_session_repository.dart';

class RejectVoiceSessionInvitationUseCase {
  final VoiceSessionRepository repository;

  RejectVoiceSessionInvitationUseCase(this.repository);

  Future<void> call(int id) async {
    return await repository.rejectInvitation(id);
  }
}
