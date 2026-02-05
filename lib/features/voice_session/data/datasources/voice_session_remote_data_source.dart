import '../api/voice_session_api.dart';
import '../dto/create_voice_session_request_dto.dart';
import '../dto/invite_users_request_dto.dart';
import '../dto/voice_session_dto.dart';

abstract class VoiceSessionRemoteDataSource {
  Future<int> createSession(CreateVoiceSessionRequestDto request);
  Future<VoiceSessionDto> getSession(int id);
  Future<List<VoiceSessionDto>> getMySessions();
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

class VoiceSessionRemoteDataSourceImpl implements VoiceSessionRemoteDataSource {
  final VoiceSessionApi api;

  VoiceSessionRemoteDataSourceImpl(this.api);

  @override
  Future<int> createSession(CreateVoiceSessionRequestDto request) async {
    return await api.createSession(request);
  }

  @override
  Future<VoiceSessionDto> getSession(int id) async {
    final json = await api.getSession(id);
    return VoiceSessionDto.fromJson(json);
  }

  @override
  Future<List<VoiceSessionDto>> getMySessions() async {
    final jsonList = await api.getMySessions();
    return jsonList.map((json) => VoiceSessionDto.fromJson(json)).toList();
  }

  @override
  Future<void> inviteUsers(int id, InviteUsersRequestDto request) async {
    return await api.inviteUsers(id, request);
  }

  @override
  Future<void> acceptInvitation(int id) async {
    return await api.acceptInvitation(id);
  }

  @override
  Future<void> rejectInvitation(int id) async {
    return await api.rejectInvitation(id);
  }

  @override
  Future<void> joinSession(int id) async {
    return await api.joinSession(id);
  }

  @override
  Future<void> leaveSession(int id) async {
    return await api.leaveSession(id);
  }

  @override
  Future<void> endSession(int id) async {
    return await api.endSession(id);
  }

  @override
  Future<void> kickUser(int sessionId, int targetUserId) async {
    return await api.kickUser(sessionId, targetUserId);
  }

  @override
  Future<void> muteUser(int sessionId, int targetUserId) async {
    return await api.muteUser(sessionId, targetUserId);
  }

  @override
  Future<void> transferHost(int sessionId, int newHostId) async {
    return await api.transferHost(sessionId, newHostId);
  }
}
