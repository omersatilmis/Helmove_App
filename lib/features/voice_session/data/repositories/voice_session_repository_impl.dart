import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/voice_session_entity.dart';
import '../../domain/repositories/voice_session_repository.dart';
import '../datasources/voice_session_remote_data_source.dart';
import '../dto/create_voice_session_request_dto.dart';
import '../dto/invite_users_request_dto.dart';

class VoiceSessionRepositoryImpl implements VoiceSessionRepository {
  final VoiceSessionRemoteDataSource remoteDataSource;

  VoiceSessionRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, int>> createSession(dynamic request) async {
    try {
      final result = await remoteDataSource.createSession(
        request as CreateVoiceSessionRequestDto,
      );
      return Right(result);
    } catch (e) {
      final message = e.toString().replaceAll('Exception: ', '');
      return Left(ServerFailure(message));
    }
  }

  @override
  Future<Either<Failure, VoiceSessionEntity>> getSession(int id) async {
    try {
      final result = await remoteDataSource.getSession(id);
      return Right(result);
    } catch (e) {
      final message = e.toString().replaceAll('Exception: ', '');
      return Left(ServerFailure(message));
    }
  }

  @override
  Future<Either<Failure, List<VoiceSessionEntity>>> getMySessions() async {
    try {
      final result = await remoteDataSource.getMySessions();
      return Right(result);
    } catch (e) {
      final message = e.toString().replaceAll('Exception: ', '');
      return Left(ServerFailure(message));
    }
  }

  @override
  Future<Either<Failure, Unit>> inviteUsers(int id, dynamic request) async {
    try {
      await remoteDataSource.inviteUsers(id, request as InviteUsersRequestDto);
      return const Right(unit);
    } catch (e) {
      final message = e.toString().replaceAll('Exception: ', '');
      return Left(ServerFailure(message));
    }
  }

  @override
  Future<Either<Failure, Unit>> acceptInvitation(int id) async {
    try {
      await remoteDataSource.acceptInvitation(id);
      return const Right(unit);
    } catch (e) {
      final message = e.toString().replaceAll('Exception: ', '');
      return Left(ServerFailure(message));
    }
  }

  @override
  Future<Either<Failure, Unit>> rejectInvitation(int id) async {
    try {
      await remoteDataSource.rejectInvitation(id);
      return const Right(unit);
    } catch (e) {
      final message = e.toString().replaceAll('Exception: ', '');
      return Left(ServerFailure(message));
    }
  }

  @override
  Future<Either<Failure, Unit>> joinSession(int id) async {
    try {
      await remoteDataSource.joinSession(id);
      return const Right(unit);
    } catch (e) {
      final message = e.toString().replaceAll('Exception: ', '');
      return Left(ServerFailure(message));
    }
  }

  @override
  Future<Either<Failure, Unit>> leaveSession(int id) async {
    try {
      await remoteDataSource.leaveSession(id);
      return const Right(unit);
    } catch (e) {
      final message = e.toString().replaceAll('Exception: ', '');
      return Left(ServerFailure(message));
    }
  }

  @override
  Future<Either<Failure, Unit>> endSession(int id) async {
    try {
      await remoteDataSource.endSession(id);
      return const Right(unit);
    } catch (e) {
      final message = e.toString().replaceAll('Exception: ', '');
      return Left(ServerFailure(message));
    }
  }

  @override
  Future<Either<Failure, Unit>> kickUser(
    int sessionId,
    int targetUserId,
  ) async {
    try {
      await remoteDataSource.kickUser(sessionId, targetUserId);
      return const Right(unit);
    } catch (e) {
      final message = e.toString().replaceAll('Exception: ', '');
      return Left(ServerFailure(message));
    }
  }

  @override
  Future<Either<Failure, Unit>> muteUser(
    int sessionId,
    int targetUserId,
  ) async {
    try {
      await remoteDataSource.muteUser(sessionId, targetUserId);
      return const Right(unit);
    } catch (e) {
      final message = e.toString().replaceAll('Exception: ', '');
      return Left(ServerFailure(message));
    }
  }

  @override
  Future<Either<Failure, Unit>> transferHost(
    int sessionId,
    int newHostId,
  ) async {
    try {
      await remoteDataSource.transferHost(sessionId, newHostId);
      return const Right(unit);
    } catch (e) {
      final message = e.toString().replaceAll('Exception: ', '');
      return Left(ServerFailure(message));
    }
  }
}
