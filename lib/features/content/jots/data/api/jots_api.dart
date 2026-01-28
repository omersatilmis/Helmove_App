import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'jots_endpoints.dart';
import '../dto/jot_dto.dart';

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

      return JotModel.fromJson(response.data);
    } catch (e) {
      throw _handleError(e, 'Jot oluşturulamadı');
    }
  }

  /// GET /api/jots/feed?page=1
  /// Gets the jot feed with pagination
  Future<List<JotModel>> getFeed({int page = 1}) async {
    try {
      debugPrint('📝 [JotsApi] getFeed - URL: ${JotsEndpoints.feed}');
      debugPrint('📝 [JotsApi] getFeed - Page: $page');

      final response = await _dio.get(
        JotsEndpoints.feed,
        queryParameters: {'page': page},
      );

      return _parseList(response.data, (json) => JotModel.fromJson(json));
    } catch (e) {
      throw _handleError(e, 'Feed alınamadı');
    }
  }

  /// GET /api/jots/user/{userId}?page=1
  /// Gets jots for a specific user with pagination
  Future<List<JotModel>> getUserJots(int userId, {int page = 1}) async {
    try {
      final url = JotsEndpoints.userJots(userId);
      debugPrint('📝 [JotsApi] getUserJots - URL: $url');
      debugPrint('📝 [JotsApi] getUserJots - UserId: $userId, Page: $page');

      final response = await _dio.get(url, queryParameters: {'page': page});

      return _parseList(response.data, (json) => JotModel.fromJson(json));
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

  // --- Helpers ---

  List<T> _parseList<T>(
    dynamic data,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final List list = data is List
        ? data
        : (data['data'] ?? data['items'] ?? data['jots'] ?? []);
    return list.map((e) => fromJson(e)).toList();
  }

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
