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
    return _isSuccess(response.statusCode);
  }

  @override
  Future<bool> unfollowUser(int userId) async {
    final response = await dio.delete(FollowEndpoints.unfollow(userId));
    return _isSuccess(response.statusCode);
  }

  @override
  Future<List<FollowUserModel>> getFollowers(int userId, {int page = 1, int pageSize = 20}) async {
    final response = await dio.get(
      FollowEndpoints.followers(userId),
      queryParameters: {'page': page, 'pageSize': pageSize},
    );
    return _parseUsers(response.data);
  }

  @override
  Future<List<FollowUserModel>> getFollowing(int userId, {int page = 1, int pageSize = 20}) async {
    final response = await dio.get(
      FollowEndpoints.following(userId),
      queryParameters: {'page': page, 'pageSize': pageSize},
    );
    return _parseUsers(response.data);
  }

  @override
  Future<List<FollowUserModel>> getMyFollowers({int page = 1, int pageSize = 20}) async {
    final response = await dio.get(
      FollowEndpoints.myFollowers,
      queryParameters: {'page': page, 'pageSize': pageSize},
    );
    return _parseUsers(response.data);
  }

  @override
  Future<List<FollowUserModel>> getMyFollowing({int page = 1, int pageSize = 20}) async {
    final response = await dio.get(
      FollowEndpoints.myFollowing,
      queryParameters: {'page': page, 'pageSize': pageSize},
    );
    return _parseUsers(response.data);
  }

  @override
  Future<bool> blockUser(int userId) async {
    final response = await dio.post(FollowEndpoints.block(userId));
    return _isSuccess(response.statusCode);
  }

  @override
  Future<bool> unblockUser(int userId) async {
    final response = await dio.post(FollowEndpoints.unblock(userId));
    return _isSuccess(response.statusCode);
  }

  @override
  Future<List<FollowUserModel>> getBlockedUsers() async {
    final response = await dio.get(FollowEndpoints.blocked);
    return _parseUsers(response.data);
  }

  bool _isSuccess(int? statusCode) {
    return statusCode != null && statusCode >= 200 && statusCode < 300;
  }

  List<FollowUserModel> _parseUsers(dynamic responseData) {
    final list = _extractList(responseData);
    return list
        .map((item) => FollowUserModel.fromJson(_toJsonMap(item)))
        .toList(growable: false);
  }

  List<dynamic> _extractList(dynamic responseData) {
    if (responseData is List) {
      return responseData;
    }

    final map = _toJsonMap(responseData);
    final dynamic firstLevel =
        map['data'] ?? map['items'] ?? map['results'] ?? map['users'];

    if (firstLevel is List) {
      return firstLevel;
    }

    if (firstLevel != null) {
      final nestedMap = _toJsonMap(firstLevel);
      final dynamic nestedList =
          nestedMap['data'] ??
          nestedMap['items'] ??
          nestedMap['results'] ??
          nestedMap['users'];
      if (nestedList is List) {
        return nestedList;
      }
    }

    throw const FormatException('Invalid follow list response format');
  }

  Map<String, dynamic> _toJsonMap(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data;
    }
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    throw const FormatException('Invalid follow response payload');
  }
}
