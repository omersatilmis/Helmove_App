import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ETagInterceptor extends Interceptor {
  static const String _ifNoneMatchHeader = 'If-None-Match';
  static const String _extraCacheKey = '__etag_cache_key';
  static const String _extraAppliedByInterceptor =
      '__etag_applied_by_interceptor';
  static const String _extraHadManualIfNoneMatch =
      '__etag_had_manual_if_none_match';
  static const String _cachePrefix = 'etag_cache';

  final SharedPreferences _sharedPreferences;

  ETagInterceptor(this._sharedPreferences);

  bool _isGet(RequestOptions options) {
    return options.method.toUpperCase() == 'GET';
  }

  String _cacheKeyFor(RequestOptions options) {
    final url = options.uri.toString();
    final encoded = base64Url.encode(utf8.encode(url));
    return '$_cachePrefix:$encoded';
  }

  String _etagKey(String cacheKey) => '$cacheKey:etag';
  String _dataKey(String cacheKey) => '$cacheKey:data';

  String? _readCachedEtag(String cacheKey) {
    final etag = _sharedPreferences.getString(_etagKey(cacheKey));
    if (etag == null || etag.trim().isEmpty) {
      return null;
    }
    return etag.trim();
  }

  dynamic _readCachedData(String cacheKey) {
    final raw = _sharedPreferences.getString(_dataKey(cacheKey));
    if (raw == null || raw.isEmpty) {
      return null;
    }

    try {
      return jsonDecode(raw);
    } catch (_) {
      return raw;
    }
  }

  Future<void> _saveCacheEntry({
    required String cacheKey,
    required String etag,
    required dynamic data,
  }) async {
    String serializedData;
    try {
      serializedData = jsonEncode(data);
    } catch (_) {
      // Non-JSON bodies are ignored for ETag cache.
      return;
    }

    await Future.wait([
      _sharedPreferences.setString(_etagKey(cacheKey), etag),
      _sharedPreferences.setString(_dataKey(cacheKey), serializedData),
    ]);
  }

  bool _hasIfNoneMatchHeader(RequestOptions options) {
    for (final entry in options.headers.entries) {
      if (entry.key.toLowerCase() == 'if-none-match') {
        return true;
      }
    }
    return false;
  }

  bool _shouldTransform304(RequestOptions options) {
    final hadManualHeader = options.extra[_extraHadManualIfNoneMatch] == true;
    if (hadManualHeader) {
      return false;
    }
    return options.extra[_extraAppliedByInterceptor] == true;
  }

  Response<dynamic> _cachedSuccessResponse({
    required RequestOptions requestOptions,
    required Response<dynamic>? sourceResponse,
    required dynamic cachedData,
  }) {
    return Response<dynamic>(
      requestOptions: requestOptions,
      data: cachedData,
      statusCode: 200,
      statusMessage: 'OK (from ETag cache)',
      headers: sourceResponse?.headers ?? Headers(),
      isRedirect: sourceResponse?.isRedirect ?? false,
      redirects: sourceResponse?.redirects ?? const <RedirectRecord>[],
      extra: sourceResponse?.extra ?? <String, dynamic>{},
    );
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    try {
      if (!_isGet(options)) {
        return handler.next(options);
      }

      final cacheKey = _cacheKeyFor(options);
      options.extra[_extraCacheKey] = cacheKey;

      final hadManualHeader = _hasIfNoneMatchHeader(options);
      options.extra[_extraHadManualIfNoneMatch] = hadManualHeader;

      if (hadManualHeader) {
        return handler.next(options);
      }

      final cachedEtag = _readCachedEtag(cacheKey);
      if (cachedEtag != null) {
        options.headers[_ifNoneMatchHeader] = cachedEtag;
        options.extra[_extraAppliedByInterceptor] = true;
      }
    } catch (_) {
      // Ignored cache reading errors to prevent breaking the request cycle
    }

    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) async {
    try {
      final options = response.requestOptions;
      if (!_isGet(options)) {
        return handler.next(response);
      }

      final cacheKey =
          options.extra[_extraCacheKey] as String? ?? _cacheKeyFor(options);
      final statusCode = response.statusCode ?? 0;

      final etag = response.headers.value('etag');
      if (statusCode >= 200 &&
          statusCode < 300 &&
          statusCode != 304 &&
          etag != null &&
          etag.trim().isNotEmpty) {
        // Safe await for cache write
        try {
          await _saveCacheEntry(
            cacheKey: cacheKey,
            etag: etag.trim(),
            data: response.data,
          );
        } catch (_) {}
      }

      if (statusCode == 304 && _shouldTransform304(options)) {
        final cachedData = _readCachedData(cacheKey);
        if (cachedData != null) {
          final resolved = _cachedSuccessResponse(
            requestOptions: options,
            sourceResponse: response,
            cachedData: cachedData,
          );
          return handler.resolve(resolved);
        }
      }
    } catch (_) {
      // Ignore cache related errors
    }

    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final response = err.response;
    final options = err.requestOptions;

    if (!_isGet(options) || response?.statusCode != 304) {
      handler.next(err);
      return;
    }

    if (!_shouldTransform304(options)) {
      handler.next(err);
      return;
    }

    final cacheKey =
        options.extra[_extraCacheKey] as String? ?? _cacheKeyFor(options);
    final cachedData = _readCachedData(cacheKey);
    if (cachedData == null) {
      handler.next(err);
      return;
    }

    final resolved = _cachedSuccessResponse(
      requestOptions: options,
      sourceResponse: response,
      cachedData: cachedData,
    );
    handler.resolve(resolved);
  }
}
