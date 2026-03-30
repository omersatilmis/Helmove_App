import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/friend_request_entity.dart';
import '../../domain/entities/friend_stats_entity.dart';
import '../../domain/entities/friend_user_entity.dart';
import '../../domain/entities/friendship_entity.dart';
import '../../domain/entities/friendship_status.dart';
import '../../domain/repositories/friendship_repository.dart';
import '../datasources/friendship_remote_datasource.dart';

class FriendshipRepositoryImpl implements FriendshipRepository {
  final FriendshipRemoteDataSource remoteDataSource;

  // Simple In-Memory Cache
  final Map<String, dynamic> _cache = {};
  final Duration _cacheDuration = const Duration(minutes: 5);
  final Map<String, DateTime> _cacheTime = {};

  FriendshipRepositoryImpl(this.remoteDataSource);

  String _errorMessage(dynamic error, String fallback) {
    final message = error.toString().replaceFirst('Exception:', '').trim();
    return message.isEmpty ? fallback : message;
  }

  void _invalidateCache(String key) {
    _cache.remove(key);
    _cacheTime.remove(key);
  }

  void _invalidateAllCaches() {
    _cache.clear();
    _cacheTime.clear();
  }

  Future<Either<Failure, T>> _getData<T>(
    String cacheKey,
    Future<T> Function() apiCall,
  ) async {
    if (_cache.containsKey(cacheKey) && _cacheTime.containsKey(cacheKey)) {
      if (DateTime.now().difference(_cacheTime[cacheKey]!) < _cacheDuration) {
        return Right(_cache[cacheKey] as T);
      }
    }

    try {
      final result = await apiCall();
      _cache[cacheKey] = result;
      _cacheTime[cacheKey] = DateTime.now();
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString())); // Assuming ServerFailure exists
    }
  }

  @override
  Future<Either<Failure, FriendshipEntity>> sendFriendRequest(
    int targetUserId,
    String message,
  ) async {
    try {
      final result = await remoteDataSource.sendFriendRequest(
        targetUserId,
        message,
      );
      _invalidateCache('pending_requests');
      _invalidateCache('sent_requests');
      _invalidateCache('stats');
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, FriendshipEntity>> acceptFriendRequest(
    int friendshipId,
  ) async {
    try {
      final result = await remoteDataSource.acceptFriendRequest(friendshipId);
      _invalidateAllCaches(); // Accepting usually changes friend list, pending, stats
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, FriendshipEntity>> rejectFriendRequest(
    int friendshipId,
  ) async {
    try {
      final result = await remoteDataSource.rejectFriendRequest(friendshipId);
      _invalidateCache('pending_requests');
      _invalidateCache('stats');
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, FriendshipEntity>> cancelSentRequest(
    int friendshipId,
  ) async {
    try {
      final result = await remoteDataSource.cancelSentRequest(friendshipId);
      _invalidateCache('sent_requests');
      _invalidateCache('pending_requests');
      _invalidateCache('stats');
      return Right(result);
    } catch (e) {
      return Left(
        ServerFailure(_errorMessage(e, 'Gonderilen istek iptal edilemedi')),
      );
    }
  }

  @override
  Future<Either<Failure, FriendshipEntity>> removeFriend(int friendId) async {
    try {
      final result = await remoteDataSource.removeFriend(friendId);
      _invalidateAllCaches();
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, FriendshipEntity>> blockUser(int targetUserId) async {
    try {
      final result = await remoteDataSource.blockUser(targetUserId);
      _invalidateAllCaches();
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, FriendshipEntity>> unblockUser(
    int targetUserId,
  ) async {
    try {
      final result = await remoteDataSource.unblockUser(targetUserId);
      _invalidateAllCaches(); // Safe bet
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<FriendUserEntity>>> getMyFriends() {
    return _getData('my_friends', () => remoteDataSource.getMyFriends());
  }

  @override
  Future<Either<Failure, List<FriendUserEntity>>> getFriends(int userId) {
    return _getData('friends_$userId', () => remoteDataSource.getFriends(userId));
  }

  @override
  Future<Either<Failure, List<FriendRequestEntity>>> getPendingRequests() {
    return _getData(
      'pending_requests',
      () => remoteDataSource.getPendingRequests(),
    );
  }

  @override
  Future<Either<Failure, List<FriendRequestEntity>>> getSentRequests() {
    return _getData('sent_requests', () => remoteDataSource.getSentRequests());
  }

  @override
  Future<Either<Failure, FriendStatsEntity>> getFriendshipStats({int? userId}) {
    final cacheKey = userId == null ? 'stats' : 'stats_$userId';
    return _getData(
      cacheKey,
      () => remoteDataSource.getFriendshipStats(userId: userId),
    );
  }

  @override
  Future<Either<Failure, List<FriendUserEntity>>> getMutualFriends(
    int targetUserId,
  ) async {
    // Usually not cached as it depends on targetUserId, unless we dynamic key
    try {
      final result = await remoteDataSource.getMutualFriends(targetUserId);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<FriendUserEntity>>> searchFriends(
    String query,
  ) async {
    try {
      final result = await remoteDataSource.searchFriends(query);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> checkAreFriends(int targetUserId) async {
    try {
      final result = await remoteDataSource.checkAreFriends(targetUserId);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, FriendshipStatus>> getFriendshipStatus(
    int targetUserId,
  ) async {
    try {
      final result = await remoteDataSource.getFriendshipStatus(targetUserId);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  void clearCache() {
    _invalidateAllCaches();
  }
}
