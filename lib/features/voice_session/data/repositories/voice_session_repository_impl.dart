import '../../domain/entities/voice_session_entity.dart';
import '../../domain/repositories/voice_session_repository.dart';
import '../datasources/voice_session_remote_data_source.dart';
import '../dto/create_voice_session_request_dto.dart';
import '../dto/invite_users_request_dto.dart';

class VoiceSessionRepositoryImpl implements VoiceSessionRepository {
  final VoiceSessionRemoteDataSource remoteDataSource;

  VoiceSessionRepositoryImpl(this.remoteDataSource);

  @override
  Future<int> createSession(CreateVoiceSessionRequestDto request) async {
    return await remoteDataSource.createSession(request);
  }

  @override
  Future<VoiceSessionEntity> getSession(int id) async {
    final dto = await remoteDataSource.getSession(id);
    return dto.toEntity();
  }

  @override
  Future<List<VoiceSessionEntity>> getMySessions() async {
    final dtos = await remoteDataSource.getMySessions();
    return dtos.map((dto) => dto.toEntity()).toList();
  }

  @override
  Future<void> inviteUsers(int id, InviteUsersRequestDto request) async {
    return await remoteDataSource.inviteUsers(id, request);
  }

  @override
  Future<void> acceptInvitation(int id) async {
    return await remoteDataSource.acceptInvitation(id);
  }

  @override
  Future<void> rejectInvitation(int id) async {
    return await remoteDataSource.rejectInvitation(id);
  }

  @override
  Future<void> joinSession(int id) async {
    return await remoteDataSource.joinSession(id);
  }

  @override
  Future<void> leaveSession(int id) async {
    return await remoteDataSource.leaveSession(id);
  }

  @override
  Future<void> endSession(int id) async {
    return await remoteDataSource.endSession(id);
  }

  @override
  Future<void> kickUser(int sessionId, int targetUserId) async {
    return await remoteDataSource.kickUser(sessionId, targetUserId);
  }

  @override
  Future<void> muteUser(int sessionId, int targetUserId) async {
    return await remoteDataSource.muteUser(sessionId, targetUserId);
  }

  @override
  Future<void> transferHost(int sessionId, int newHostId) async {
    return await remoteDataSource.transferHost(sessionId, newHostId);
  }
}
