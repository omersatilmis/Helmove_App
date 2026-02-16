import 'dart:async';

import 'package:dio/dio.dart';

import '../../features/auth/data/datasources/auth_local_data_source.dart';
import '../../features/auth/data/dto/login_response_dto.dart';

class AuthInterceptor extends Interceptor {
  final Dio _dio;
  final Dio _refreshDio;
  final AuthLocalDataSource _localDataSource;
  final Future<void> Function()? _onAuthInvalidated;
  final Future<void> Function(String token)? _onTokenRefreshed;

  Future<void>? _refreshInFlight;

  AuthInterceptor(
    this._dio,
    this._refreshDio,
    this._localDataSource,
    this._onAuthInvalidated,
    this._onTokenRefreshed,
  );

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final accessToken = await _localDataSource.getToken();
    if (accessToken != null && accessToken.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $accessToken';
    }

    // Only attach refresh token when the backend explicitly expects it.
    if (_requiresRefreshTokenHeader(options.path)) {
      final refreshToken = await _localDataSource.getRefreshToken();
      if (refreshToken != null && refreshToken.isNotEmpty) {
        options.headers['X-Refresh-Token'] = refreshToken;
      }
    }

    super.onRequest(options, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final statusCode = err.response?.statusCode;
    final requestOptions = err.requestOptions;

    final isUnauthorized = statusCode == 401;
    final alreadyRetried = requestOptions.extra['__auth_retry'] == true;

    if (!isUnauthorized || alreadyRetried || _isAuthRequest(requestOptions.path)) {
      return super.onError(err, handler);
    }

    try {
      await _refreshTokens();

      final newAccessToken = await _localDataSource.getToken();
      if (newAccessToken == null || newAccessToken.isEmpty) {
        return super.onError(err, handler);
      }

      final response = await _retryWithToken(requestOptions, newAccessToken);
      return handler.resolve(response);
    } catch (_) {
      // If refresh fails, clear auth so UI can route to login.
      await _localDataSource.clearAuthData();
      final onAuthInvalidated = _onAuthInvalidated;
      if (onAuthInvalidated != null) {
        try {
          await onAuthInvalidated();
        } catch (_) {}
      }
      return super.onError(err, handler);
    }
  }

  bool _isAuthRequest(String path) {
    final p = path.toLowerCase();
    return p.contains('api/auth/login') ||
        p.contains('api/auth/register') ||
        p.contains('api/auth/refresh-token') ||
        p.contains('api/auth/forgot-password') ||
        p.contains('api/auth/reset-password');
  }

  bool _requiresRefreshTokenHeader(String path) {
    final p = path.toLowerCase();
    return p.contains('api/auth/sessions') ||
        p.contains('api/auth/logout') ||
        p.contains('api/auth/revoke-token');
  }

  Future<void> _refreshTokens() async {
    if (_refreshInFlight != null) return _refreshInFlight!;

    final completer = Completer<void>();
    _refreshInFlight = completer.future;

    try {
      final refreshToken = await _localDataSource.getRefreshToken();
      if (refreshToken == null || refreshToken.trim().isEmpty) {
        throw StateError('Missing refresh token');
      }

      final response = await _refreshDio.post(
        'api/auth/refresh-token',
        data: {'refreshToken': refreshToken},
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      final dto = LoginResponseDto.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
      if (!dto.success || dto.data == null) {
        throw StateError(dto.message ?? 'Refresh failed');
      }

      final access = dto.data!.token;
      final newRefresh = dto.data!.refreshToken;
      if (access.isEmpty || newRefresh == null || newRefresh.trim().isEmpty) {
        throw StateError('Refresh did not return rotated tokens');
      }

      await _localDataSource.saveToken(access);
      await _localDataSource.saveRefreshToken(newRefresh);
      final onTokenRefreshed = _onTokenRefreshed;
      if (onTokenRefreshed != null) {
        try {
          await onTokenRefreshed(access);
        } catch (_) {}
      }

      completer.complete();
    } catch (e) {
      completer.completeError(e);
      rethrow;
    } finally {
      _refreshInFlight = null;
    }
  }

  Future<Response<dynamic>> _retryWithToken(
    RequestOptions requestOptions,
    String accessToken,
  ) async {
    final headers = Map<String, dynamic>.from(requestOptions.headers);
    headers['Authorization'] = 'Bearer $accessToken';

    final extra = Map<String, dynamic>.from(requestOptions.extra);
    extra['__auth_retry'] = true;

    return _dio.request<dynamic>(
      requestOptions.path,
      data: requestOptions.data,
      queryParameters: requestOptions.queryParameters,
      options: Options(
        method: requestOptions.method,
        headers: headers,
        responseType: requestOptions.responseType,
        contentType: requestOptions.contentType,
        followRedirects: requestOptions.followRedirects,
        validateStatus: requestOptions.validateStatus,
        receiveDataWhenStatusError: requestOptions.receiveDataWhenStatusError,
        extra: extra,
        sendTimeout: requestOptions.sendTimeout,
        receiveTimeout: requestOptions.receiveTimeout,
      ),
      cancelToken: requestOptions.cancelToken,
      onReceiveProgress: requestOptions.onReceiveProgress,
      onSendProgress: requestOptions.onSendProgress,
    );
  }
}
