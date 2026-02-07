import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/voice_session_entity.dart';

abstract class VoiceSessionRepository {
  Future<Either<Failure, int>> createSession(dynamic request);
  Future<Either<Failure, VoiceSessionEntity>> getSession(int id);
  Future<Either<Failure, List<VoiceSessionEntity>>> getMySessions();
  Future<Either<Failure, Unit>> inviteUsers(int id, dynamic request);
  Future<Either<Failure, Unit>> acceptInvitation(int id);
  Future<Either<Failure, Unit>> rejectInvitation(int id);
  Future<Either<Failure, Unit>> joinSession(int id);
  Future<Either<Failure, Unit>> leaveSession(int id);
  Future<Either<Failure, Unit>> endSession(int id);

  // Moderator methods
  Future<Either<Failure, Unit>> kickUser(int sessionId, int targetUserId);
  Future<Either<Failure, Unit>> muteUser(int sessionId, int targetUserId);
  Future<Either<Failure, Unit>> transferHost(int sessionId, int newHostId);
}
