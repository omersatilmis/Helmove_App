import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../friendship/data/dto/friend_user_dto.dart';
import '../../../profile/data/api/profile_endpoints.dart';
import '../../../content/posts/data/models/post_model.dart';
import '../../../../core/models/paged_result.dart';
import '../../../../core/models/pagination_metadata.dart';

class DiscoverApi {
  final Dio _dio;

  DiscoverApi(this._dio);

  /// KullanÄ±cÄ± arama
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
        'ğŸ” [DiscoverApi] searchUsers - URL: ${ProfileEndpoints.search}',
      );
      debugPrint('ğŸ” [DiscoverApi] searchUsers - Params: $queryParams');

      final response = await _dio.get(
        ProfileEndpoints.search,
        queryParameters: queryParams,
      );

      return _parseList(
        response.data,
        (json) => FriendUserModel.fromJson(json),
      );
    } catch (e) {
      throw _handleError(e, 'KullanÄ±cÄ± aramasÄ± baÅŸarÄ±sÄ±z');
    }
  }

  /// KeÅŸfet iÃ§eriÄŸi â€” herkese aÃ§Ä±k postlar (arkadaÅŸ/takip filtresi yok)
  Future<PagedResult<PostModel>> getExploreContent({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _dio.get(
        '/api/posts/explore',
        queryParameters: {'page': page, 'limit': limit},
      );

      final data = response.data is Map
          ? Map<String, dynamic>.from(response.data as Map)
          : <String, dynamic>{};
      final List<dynamic> itemsData = data['data'] ?? [];
      final items = itemsData.map((e) => PostModel.fromJson(e)).toList();

      final metaData = data['meta'];
      final meta = metaData != null
          ? PaginationMetadata.fromJson(metaData)
          : PaginationMetadata.initial();

      return PagedResult(items: items, metadata: meta);
    } catch (e) {
      throw _handleError(e, 'KeÅŸfet iÃ§eriÄŸi yÃ¼klenemedi');
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

