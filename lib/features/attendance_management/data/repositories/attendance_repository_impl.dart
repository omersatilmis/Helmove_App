import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/participant_entity.dart';
import '../../domain/entities/participation_status_entity.dart';
import 'package:helmove/features/attendance_management/domain/repositories/attendance_repository.dart';
import '../datasources/attendance_remote_data_source.dart';

class AttendanceRepositoryImpl implements AttendanceRepository {
  final AttendanceRemoteDataSource remoteDataSource;

  AttendanceRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, Unit>> joinGroupRide(
    int rideId, {
    String? joinMessage,
  }) async {
    try {
      await remoteDataSource.joinGroupRide(rideId, joinMessage: joinMessage);
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> leaveGroupRide(int rideId) async {
    try {
      await remoteDataSource.leaveGroupRide(rideId);
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> approveParticipant(
    int rideId,
    int userId,
  ) async {
    try {
      await remoteDataSource.approveParticipant(rideId, userId);
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> rejectParticipant(
    int rideId,
    int userId,
  ) async {
    try {
      await remoteDataSource.rejectParticipant(rideId, userId);
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ParticipantEntity>>> getRideParticipants(
    int rideId,
  ) async {
    try {
      final result = await remoteDataSource.getRideParticipants(rideId);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ParticipationStatusEntity>> getParticipationStatus(
    int rideId,
  ) async {
    try {
      final result = await remoteDataSource.getParticipationStatus(rideId);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
