import 'package:dio/dio.dart';
import '../models/follow_user_model.dart';
import 'follow_endpoints.dart';

abstract class FollowRemoteDataSource {
  Future<bool> followUser(int userId);
  Future<bool> unfollowUser(int userId);
  Future<List<FollowUserModel>> getFollowers(int userId, {int page = 1, int pageSize = 20});
  Future<List<FollowUserModel>> getFollowing(int userId, {int page = 1, int pageSize = 20});
  Future<List<FollowUserModel>> getMyFollowers({int page = 1, int pageSize = 20});
  Future<List<FollowUserModel>> getMyFollowing({int page = 1, int pageSize = 20});
  Future<bool> blockUser(int userId);
  Future<bool> unblockUser(int userId);
  Future<List<FollowUserModel>> getBlockedUsers();
}

class FollowRemoteDataSourceImpl implements FollowRemoteDataSource {
  final Dio dio;

  FollowRemoteDataSourceImpl({required this.dio});

  @override
  Future<bool> followUser(int userId) async {
    final response = await dio.post(FollowEndpoints.follow(userId));
    return response.statusCode == 200;
  }

  @override
  Future<bool> unfollowUser(int userId) async {
    final response = await dio.delete(FollowEndpoints.unfollow(userId));
    return response.statusCode == 200;
  }

  @override
  Future<List<FollowUserModel>> getFollowers(int userId, {int page = 1, int pageSize = 20}) async {
    final response = await dio.get(
      FollowEndpoints.followers(userId),
      queryParameters: {'page': page, 'pageSize': pageSize},
    );
    return (response.data['data'] as List)
        .map((json) => FollowUserModel.fromJson(json))
        .toList();
  }

  @override
  Future<List<FollowUserModel>> getFollowing(int userId, {int page = 1, int pageSize = 20}) async {
    final response = await dio.get(
      FollowEndpoints.following(userId),
      queryParameters: {'page': page, 'pageSize': pageSize},
    );
    return (response.data['data'] as List)
        .map((json) => FollowUserModel.fromJson(json))
        .toList();
  }

  @override
  Future<List<FollowUserModel>> getMyFollowers({int page = 1, int pageSize = 20}) async {
    final response = await dio.get(
      FollowEndpoints.myFollowers,
      queryParameters: {'page': page, 'pageSize': pageSize},
    );
    return (response.data['data'] as List)
        .map((json) => FollowUserModel.fromJson(json))
        .toList();
  }

  @override
  Future<List<FollowUserModel>> getMyFollowing({int page = 1, int pageSize = 20}) async {
    final response = await dio.get(
      FollowEndpoints.myFollowing,
      queryParameters: {'page': page, 'pageSize': pageSize},
    );
    return (response.data['data'] as List)
        .map((json) => FollowUserModel.fromJson(json))
        .toList();
  }

  @override
  Future<bool> blockUser(int userId) async {
    final response = await dio.post(FollowEndpoints.block(userId));
    return response.statusCode == 200;
  }

  @override
  Future<bool> unblockUser(int userId) async {
    final response = await dio.post(FollowEndpoints.unblock(userId));
    return response.statusCode == 200;
  }

  @override
  Future<List<FollowUserModel>> getBlockedUsers() async {
    final response = await dio.get(FollowEndpoints.blocked);
    return (response.data['data'] as List)
        .map((json) => FollowUserModel.fromJson(json))
        .toList();
  }
}
