import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/follow_user.dart';

abstract class FollowRepository {
  Future<Either<Failure, bool>> followUser(int userId);
  Future<Either<Failure, bool>> unfollowUser(int userId);
  Future<Either<Failure, List<FollowUser>>> getFollowers(int userId, {int page = 1, int pageSize = 20});
  Future<Either<Failure, List<FollowUser>>> getFollowing(int userId, {int page = 1, int pageSize = 20});
  Future<Either<Failure, List<FollowUser>>> getMyFollowers({int page = 1, int pageSize = 20});
  Future<Either<Failure, List<FollowUser>>> getMyFollowing({int page = 1, int pageSize = 20});
  Future<Either<Failure, bool>> blockUser(int userId);
  Future<Either<Failure, bool>> unblockUser(int userId);
  Future<Either<Failure, List<FollowUser>>> getBlockedUsers();
}
