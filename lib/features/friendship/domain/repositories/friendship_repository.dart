import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/friend_request_entity.dart';
import '../entities/friend_stats_entity.dart';
import '../entities/friend_user_entity.dart';
import '../entities/friendship_entity.dart';
import '../entities/friendship_status.dart';

abstract class FriendshipRepository {
  // Actions
  Future<Either<Failure, FriendshipEntity>> sendFriendRequest(
    int targetUserId,
    String message,
  );
  Future<Either<Failure, FriendshipEntity>> acceptFriendRequest(
    int friendshipId,
  );
  Future<Either<Failure, FriendshipEntity>> rejectFriendRequest(
    int friendshipId,
  );
  Future<Either<Failure, FriendshipEntity>> removeFriend(int friendId);
  Future<Either<Failure, FriendshipEntity>> blockUser(int targetUserId);
  Future<Either<Failure, FriendshipEntity>> unblockUser(int targetUserId);

  // Lists & Data
  Future<Either<Failure, List<FriendUserEntity>>> getMyFriends();
  Future<Either<Failure, List<FriendRequestEntity>>> getPendingRequests();
  Future<Either<Failure, List<FriendRequestEntity>>> getSentRequests();
  Future<Either<Failure, FriendStatsEntity>> getFriendshipStats();
  Future<Either<Failure, List<FriendUserEntity>>> getMutualFriends(
    int targetUserId,
  );
  Future<Either<Failure, List<FriendUserEntity>>> searchFriends(String query);

  // Status Checks
  Future<Either<Failure, bool>> checkAreFriends(int targetUserId);
  Future<Either<Failure, FriendshipStatus>> getFriendshipStatus(
    int targetUserId,
  );
}
