import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../friendship/data/dto/friend_user_dto.dart';
import '../../../profile/data/api/profile_endpoints.dart';

class DiscoverApi {
  final Dio _dio;

  DiscoverApi(this._dio);

  /// GET /api/Friendship/search?searchTerm=query&city=city&limit=limit
  /// Reusing Friendship endpoints as the base search is likely similar or the same.
  /// If there's a specific 'Discover' endpoint, we should use that.
  /// Based on user request "search users", and existing FriendshipApi, we'll try to use the same endpoint
  /// but maybe with extra parameters if supported, OR we might need a new endpoint.
  /// Given the prompt implies "Discover" like Instagram, let's assume we use the existing search
  /// but maybe we should add query params if the backend supports it.
  /// for now: queryParameters: {'searchTerm': query}

  Future<List<FriendUserModel>> searchUsers(
    String query, {
    String? city,
    int limit = 20,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'searchTerm': query,
        'limit': limit,
      };

      if (city != null && city.isNotEmpty) {
        queryParams['city'] = city;
      }

      debugPrint(
        '🔍 [DiscoverApi] searchUsers - URL: ${ProfileEndpoints.search}',
      );
      debugPrint('🔍 [DiscoverApi] searchUsers - Params: $queryParams');

      final response = await _dio.get(
        ProfileEndpoints.search, // ✅ Profile search - tüm kullanıcılar
        queryParameters: queryParams,
      );

      return _parseList(
        response.data,
        (json) => FriendUserModel.fromJson(json),
      );
    } catch (e) {
      throw _handleError(e, 'Kullanıcı araması başarısız');
    }
  }

  List<T> _parseList<T>(
    dynamic data,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final List list = data is List
        ? data
        : (data['data'] ?? data['items'] ?? []);
    return list.map((e) => fromJson(e)).toList();
  }

  Exception _handleError(dynamic e, String defaultMessage) {
    if (e is DioException) {
      return Exception("$defaultMessage: ${e.response?.statusCode}");
    }
    return Exception("$defaultMessage: $e");
  }
}
