import '../../data/dto/create_voice_session_request_dto.dart';
import '../../data/dto/invite_users_request_dto.dart';
import '../entities/voice_session_entity.dart';

abstract class VoiceSessionRepository {
  Future<int> createSession(CreateVoiceSessionRequestDto request);
  Future<VoiceSessionEntity> getSession(int id);
  Future<List<VoiceSessionEntity>> getMySessions();
  Future<void> inviteUsers(int id, InviteUsersRequestDto request);
  Future<void> acceptInvitation(int id);
  Future<void> rejectInvitation(int id);
  Future<void> joinSession(int id);
  Future<void> leaveSession(int id);
  Future<void> endSession(int id);
  Future<void> kickUser(int sessionId, int targetUserId);
  Future<void> muteUser(int sessionId, int targetUserId);
  Future<void> transferHost(int sessionId, int newHostId);
}
