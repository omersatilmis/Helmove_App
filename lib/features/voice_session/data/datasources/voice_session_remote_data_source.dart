import '../api/voice_session_api.dart';
import '../dto/create_voice_session_request_dto.dart';
import '../dto/invite_users_request_dto.dart';
import '../models/voice_session_model.dart';

abstract class VoiceSessionRemoteDataSource {
  Future<int> createSession(CreateVoiceSessionRequestDto request);
  Future<VoiceSessionModel> getSession(int id);
  Future<List<VoiceSessionModel>> getMySessions();
  Future<void> inviteUsers(int id, InviteUsersRequestDto request);
  Future<void> acceptInvitation(int id);
  Future<void> rejectInvitation(int id);
  Future<void> joinSession(int id);
  Future<void> leaveSession(int id);
  Future<void> endSession(int id);

  // Extra moderator methods
  Future<void> kickUser(int sessionId, int targetUserId);
  Future<void> muteUser(int sessionId, int targetUserId);
  Future<void> transferHost(int sessionId, int newHostId);
}

class VoiceSessionRemoteDataSourceImpl implements VoiceSessionRemoteDataSource {
  final VoiceSessionApi _api;

  VoiceSessionRemoteDataSourceImpl(this._api);

  @override
  Future<int> createSession(CreateVoiceSessionRequestDto request) async {
    return await _api.createSession(request);
  }

  @override
  Future<VoiceSessionModel> getSession(int id) async {
    return await _api.getSession(id);
  }

  @override
  Future<List<VoiceSessionModel>> getMySessions() async {
    return await _api.getMySessions();
  }

  @override
  Future<void> inviteUsers(int id, InviteUsersRequestDto request) async {
    return await _api.inviteUsers(id, request);
  }

  @override
  Future<void> acceptInvitation(int id) async {
    return await _api.acceptInvitation(id);
  }

  @override
  Future<void> rejectInvitation(int id) async {
    return await _api.rejectInvitation(id);
  }

  @override
  Future<void> joinSession(int id) async {
    return await _api.joinSession(id);
  }

  @override
  Future<void> leaveSession(int id) async {
    return await _api.leaveSession(id);
  }

  @override
  Future<void> endSession(int id) async {
    return await _api.endSession(id);
  }

  @override
  Future<void> kickUser(int sessionId, int targetUserId) async {
    return await _api.kickUser(sessionId, targetUserId);
  }

  @override
  Future<void> muteUser(int sessionId, int targetUserId) async {
    return await _api.muteUser(sessionId, targetUserId);
  }

  @override
  Future<void> transferHost(int sessionId, int newHostId) async {
    return await _api.transferHost(sessionId, newHostId);
  }
}
