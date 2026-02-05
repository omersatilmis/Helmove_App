import '../../data/dto/invite_users_request_dto.dart';
import '../repositories/voice_session_repository.dart';

class InviteToVoiceSessionUseCase {
  final VoiceSessionRepository repository;

  InviteToVoiceSessionUseCase(this.repository);

  Future<void> call(int id, InviteUsersRequestDto request) async {
    return await repository.inviteUsers(id, request);
  }
}
