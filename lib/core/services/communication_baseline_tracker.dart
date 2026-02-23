import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

import '../utils/app_logger.dart';

class CommunicationBaselineSnapshot {
  final String label;
  final DateTime startedAt;
  final Duration elapsed;
  final int apiRequestCount;
  final int apiResponseCount;
  final int apiErrorCount;
  final int api404Count;
  final int apiTimeoutCount;
  final int signalREventCount;
  final Map<String, int> apiRequestsByRoute;
  final Map<String, int> apiErrorsByRoute;
  final Map<String, int> apiStatusByRoute;
  final Map<String, int> signalREventsByName;

  const CommunicationBaselineSnapshot({
    required this.label,
    required this.startedAt,
    required this.elapsed,
    required this.apiRequestCount,
    required this.apiResponseCount,
    required this.apiErrorCount,
    required this.api404Count,
    required this.apiTimeoutCount,
    required this.signalREventCount,
    required this.apiRequestsByRoute,
    required this.apiErrorsByRoute,
    required this.apiStatusByRoute,
    required this.signalREventsByName,
  });

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'startedAt': startedAt.toIso8601String(),
      'elapsedSeconds': elapsed.inSeconds,
      'api': {
        'requestCount': apiRequestCount,
        'responseCount': apiResponseCount,
        'errorCount': apiErrorCount,
        'notFound404Count': api404Count,
        'timeoutCount': apiTimeoutCount,
        'requestsByRoute': apiRequestsByRoute,
        'errorsByRoute': apiErrorsByRoute,
        'statusByRoute': apiStatusByRoute,
      },
      'signalR': {
        'eventCount': signalREventCount,
        'eventsByName': signalREventsByName,
      },
    };
  }
}

class CommunicationBaselineTracker {
  CommunicationBaselineTracker._();

  static final CommunicationBaselineTracker instance =
      CommunicationBaselineTracker._();

  static const Duration _defaultPeriodicLogInterval = Duration(seconds: 30);
  static const int _topRouteCount = 8;

  final Map<String, int> _apiRequestsByRoute = <String, int>{};
  final Map<String, int> _apiErrorsByRoute = <String, int>{};
  final Map<String, int> _apiStatusByRoute = <String, int>{};
  final Map<String, int> _signalREventsByName = <String, int>{};

  Timer? _periodicLogTimer;
  DateTime _startedAt = DateTime.now();
  String _label = 'default';
  bool _active = false;
  int _apiRequestCount = 0;
  int _apiResponseCount = 0;
  int _apiErrorCount = 0;
  int _api404Count = 0;
  int _apiTimeoutCount = 0;
  int _signalREventCount = 0;

  void startNewWindow({
    String label = 'manual',
    Duration periodicLogInterval = _defaultPeriodicLogInterval,
  }) {
    _label = label;
    _startedAt = DateTime.now();
    _active = true;
    _apiRequestCount = 0;
    _apiResponseCount = 0;
    _apiErrorCount = 0;
    _api404Count = 0;
    _apiTimeoutCount = 0;
    _signalREventCount = 0;
    _apiRequestsByRoute.clear();
    _apiErrorsByRoute.clear();
    _apiStatusByRoute.clear();
    _signalREventsByName.clear();

    _periodicLogTimer?.cancel();
    _periodicLogTimer = Timer.periodic(periodicLogInterval, (_) {
      logSnapshot(reason: 'periodic');
    });

    AppLogger.info(
      '[BASELINE] window-start label=$_label startedAt=${_startedAt.toIso8601String()}',
    );
  }

  void stopWindow({String reason = 'manual_stop'}) {
    if (!_active) return;
    logSnapshot(reason: reason);
    _periodicLogTimer?.cancel();
    _periodicLogTimer = null;
    _active = false;
  }

  void recordApiRequest(RequestOptions options) {
    _ensureActiveWindow();
    _apiRequestCount += 1;
    _increment(
      _apiRequestsByRoute,
      _routeKey(method: options.method, path: options.path),
    );
  }

  void recordApiResponse(Response<dynamic> response) {
    _ensureActiveWindow();
    _apiResponseCount += 1;
    final route = _routeKey(
      method: response.requestOptions.method,
      path: response.requestOptions.path,
    );
    final status = response.statusCode ?? -1;
    _increment(_apiStatusByRoute, '$route#$status');
    if (status == 404) {
      _api404Count += 1;
    }
  }

  void recordApiError(DioException error) {
    _ensureActiveWindow();
    _apiErrorCount += 1;
    final request = error.requestOptions;
    final route = _routeKey(method: request.method, path: request.path);
    _increment(_apiErrorsByRoute, route);

    final status = error.response?.statusCode;
    if (status != null) {
      _increment(_apiStatusByRoute, '$route#$status');
      if (status == 404) {
        _api404Count += 1;
      }
    }

    if (_isTimeout(error)) {
      _apiTimeoutCount += 1;
    }
  }

  void recordSignalREvent(String eventName) {
    _ensureActiveWindow();
    _signalREventCount += 1;
    _increment(_signalREventsByName, eventName);
  }

  CommunicationBaselineSnapshot snapshot() {
    return CommunicationBaselineSnapshot(
      label: _label,
      startedAt: _startedAt,
      elapsed: DateTime.now().difference(_startedAt),
      apiRequestCount: _apiRequestCount,
      apiResponseCount: _apiResponseCount,
      apiErrorCount: _apiErrorCount,
      api404Count: _api404Count,
      apiTimeoutCount: _apiTimeoutCount,
      signalREventCount: _signalREventCount,
      apiRequestsByRoute: _topEntries(_apiRequestsByRoute),
      apiErrorsByRoute: _topEntries(_apiErrorsByRoute),
      apiStatusByRoute: _topEntries(_apiStatusByRoute),
      signalREventsByName: _topEntries(_signalREventsByName),
    );
  }

  void logSnapshot({String reason = 'manual'}) {
    if (!_active) return;
    final data = snapshot().toJson();
    AppLogger.info('[BASELINE][$reason] ${jsonEncode(data)}');
  }

  void _ensureActiveWindow() {
    if (_active) return;
    startNewWindow(label: 'auto');
  }

  static bool _isTimeout(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return true;
      default:
        final text = error.message?.toLowerCase() ?? '';
        return text.contains('timeout') || text.contains('timed out');
    }
  }

  static String _routeKey({required String method, required String path}) {
    final normalizedMethod = method.toUpperCase();
    final normalizedPath = _normalizePath(path);
    return '$normalizedMethod $normalizedPath';
  }

  static String _normalizePath(String rawPath) {
    final trimmed = rawPath.trim();
    if (trimmed.isEmpty) return '/';

    String path;
    final uri = Uri.tryParse(trimmed);
    if (uri != null && uri.hasScheme) {
      path = uri.path;
    } else {
      final queryIndex = trimmed.indexOf('?');
      path = queryIndex >= 0 ? trimmed.substring(0, queryIndex) : trimmed;
    }

    path = path.replaceAll(RegExp(r'/\d+(?=/|$)'), '/:id');
    path = path.replaceAll(
      RegExp(
        r'/[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}(?=/|$)',
      ),
      '/:uuid',
    );

    if (!path.startsWith('/')) {
      path = '/$path';
    }
    return path;
  }

  static void _increment(Map<String, int> map, String key) {
    map[key] = (map[key] ?? 0) + 1;
  }

  static Map<String, int> _topEntries(Map<String, int> source) {
    final entries = source.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = entries.take(_topRouteCount);
    return {for (final entry in top) entry.key: entry.value};
  }
}
