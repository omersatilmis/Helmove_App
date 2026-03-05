import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'jots_endpoints.dart';
import '../dto/jot_dto.dart';
import '../../../../../core/models/conditional_fetch_result.dart';
import '../../../../../core/models/paged_result.dart';
import '../../../../../core/models/pagination_metadata.dart';

class JotsApi {
  final Dio _dio;

  JotsApi(this._dio);

  /// POST /api/jots
  /// Creates a new jot
  Future<JotModel> createJot(CreateJotRequest request) async {
    try {
      debugPrint('📝 [JotsApi] createJot - URL: ${JotsEndpoints.createJot}');
      debugPrint('📝 [JotsApi] createJot - Body: ${request.toJson()}');

      final response = await _dio.post(
        JotsEndpoints.createJot,
        data: request.toJson(),
      );

      final dynamic responseData = response.data;
      final Map<String, dynamic> jotJson =
          (responseData is Map<String, dynamic> &&
              responseData.containsKey('data'))
          ? responseData['data']
          : responseData;

      return JotModel.fromJson(jotJson);
    } catch (e) {
      throw _handleError(e, 'Jot oluşturulamadı');
    }
  }

  /// GET /api/jots/feed?page=1
  /// Gets the jot feed with pagination
  Future<ConditionalFetchResult<PagedResult<JotModel>>> getFeed({
    int page = 1,
    int limit = 10,
    String? ifNoneMatch,
  }) async {
    try {
      final shouldUseConditionalRequest =
          page == 1 && ifNoneMatch != null && ifNoneMatch.trim().isNotEmpty;

      final headers = <String, dynamic>{};
      if (shouldUseConditionalRequest) {
        headers['If-None-Match'] = ifNoneMatch.trim();
      }

      debugPrint('📝 [JotsApi] getFeed - URL: ${JotsEndpoints.feed}');
      debugPrint('📝 [JotsApi] getFeed - Page: $page');

      final response = await _dio.get(
        JotsEndpoints.feed,
        queryParameters: {'page': page, 'limit': limit},
        options: shouldUseConditionalRequest
            ? Options(
                headers: headers,
                validateStatus: (status) =>
                    status != null &&
                    ((status >= 200 && status < 300) || status == 304),
              )
            : null,
      );

      final statusCode = response.statusCode ?? 0;
      final etag = response.headers.value('etag');
      if (statusCode == 304) {
        return ConditionalFetchResult(
          data: null,
          etag: etag ?? ifNoneMatch,
          notModified: true,
        );
      }

      final data = response.data is Map
          ? Map<String, dynamic>.from(response.data as Map)
          : <String, dynamic>{};
      final List<dynamic> itemsData = data['data'] ?? [];
      final items = itemsData.map((e) => JotModel.fromJson(e)).toList();

      final metaData = data['meta'];
      final meta = metaData != null
          ? PaginationMetadata.fromJson(metaData)
          : PaginationMetadata.initial();

      return ConditionalFetchResult(
        data: PagedResult(items: items, metadata: meta),
        etag: etag,
        notModified: false,
      );
    } catch (e) {
      throw _handleError(e, 'Feed alınamadı');
    }
  }

  /// GET /api/jots/user/{userId}?page=1
  /// Gets jots for a specific user with pagination
  Future<PagedResult<JotModel>> getUserJots(
    int userId, {
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final url = JotsEndpoints.userJots(userId);
      debugPrint('📝 [JotsApi] getUserJots - URL: $url');
      debugPrint('📝 [JotsApi] getUserJots - UserId: $userId, Page: $page');

      final response = await _dio.get(
        url,
        queryParameters: {'page': page, 'limit': limit},
      );

      final data = response.data is Map
          ? Map<String, dynamic>.from(response.data as Map)
          : <String, dynamic>{};
      final List<dynamic> itemsData = data['data'] ?? [];
      final items = itemsData.map((e) => JotModel.fromJson(e)).toList();

      final metaData = data['meta'];
      final meta = metaData != null
          ? PaginationMetadata.fromJson(metaData)
          : PaginationMetadata.initial();

      return PagedResult(items: items, metadata: meta);
    } catch (e) {
      throw _handleError(e, 'Kullanıcı jotları alınamadı');
    }
  }

  /// DELETE /api/jots/{id}
  /// Deletes a jot by ID
  Future<void> deleteJot(int id) async {
    try {
      final url = JotsEndpoints.deleteJot(id);
      debugPrint('📝 [JotsApi] deleteJot - URL: $url');

      await _dio.delete(url);
    } catch (e) {
      throw _handleError(e, 'Jot silinemedi');
    }
  }

  /// POST /api/likes/{id} (Unified)
  Future<void> likeJot(int id) async {
    try {
      // Using unified endpoint
      await _dio.post('/api/likes/$id');
    } catch (e) {
      throw _handleError(e, 'Beğeni işlemi başarısız');
    }
  }

  /// DELETE /api/likes/{id} (Unified)
  Future<void> unlikeJot(int id) async {
    try {
      // Using unified endpoint
      await _dio.delete('/api/likes/$id');
    } catch (e) {
      throw _handleError(e, 'Beğeni kaldırma işlemi başarısız');
    }
  }

  // --- Helpers ---

  Exception _handleError(dynamic e, String defaultMessage) {
    if (e is DioException) {
      final errorMessage =
          _parseErrorMessage(e.response?.data) ??
          '$defaultMessage: ${e.response?.statusCode}';
      return Exception(errorMessage);
    }
    return Exception('$defaultMessage: $e');
  }

  String? _parseErrorMessage(dynamic data) {
    if (data == null) return null;
    if (data is Map<String, dynamic>) {
      return data['message'] ??
          data['detail'] ??
          data['error'] ??
          data['description'];
    }
    if (data is String) return data;
    return null;
  }
}
