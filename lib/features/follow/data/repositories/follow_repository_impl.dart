import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/follow_user.dart';
import '../../domain/repositories/follow_repository.dart';
import '../data_sources/follow_remote_data_source.dart';

class FollowRepositoryImpl implements FollowRepository {
  final FollowRemoteDataSource remoteDataSource;

  FollowRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, bool>> followUser(int userId) async {
    try {
      final result = await remoteDataSource.followUser(userId);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> unfollowUser(int userId) async {
    try {
      final result = await remoteDataSource.unfollowUser(userId);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<FollowUser>>> getFollowers(int userId, {int page = 1, int pageSize = 20}) async {
    try {
      final result = await remoteDataSource.getFollowers(userId, page: page, pageSize: pageSize);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<FollowUser>>> getFollowing(int userId, {int page = 1, int pageSize = 20}) async {
    try {
      final result = await remoteDataSource.getFollowing(userId, page: page, pageSize: pageSize);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<FollowUser>>> getMyFollowers({int page = 1, int pageSize = 20}) async {
    try {
      final result = await remoteDataSource.getMyFollowers(page: page, pageSize: pageSize);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<FollowUser>>> getMyFollowing({int page = 1, int pageSize = 20}) async {
    try {
      final result = await remoteDataSource.getMyFollowing(page: page, pageSize: pageSize);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> blockUser(int userId) async {
    try {
      final result = await remoteDataSource.blockUser(userId);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> unblockUser(int userId) async {
    try {
      final result = await remoteDataSource.unblockUser(userId);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<FollowUser>>> getBlockedUsers() async {
    try {
      final result = await remoteDataSource.getBlockedUsers();
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
