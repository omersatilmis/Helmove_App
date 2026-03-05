import 'package:dio/dio.dart';

class HomeSummaryData {
  final int unreadMessageCount;
  final int unreadNotificationCount;

  const HomeSummaryData({
    required this.unreadMessageCount,
    required this.unreadNotificationCount,
  });

  factory HomeSummaryData.fromJson(Map<String, dynamic> json) {
    int readInt(List<dynamic> values) {
      for (final value in values) {
        if (value == null) continue;
        if (value is int) return value;
        final parsed = int.tryParse(value.toString());
        if (parsed != null) return parsed;
      }
      return 0;
    }

    final messagesObj = json['messages'];
    final notificationsObj = json['notifications'];
    final messagesMap = messagesObj is Map
        ? Map<String, dynamic>.from(messagesObj)
        : <String, dynamic>{};
    final notificationsMap = notificationsObj is Map
        ? Map<String, dynamic>.from(notificationsObj)
        : <String, dynamic>{};

    return HomeSummaryData(
      unreadMessageCount: readInt([
        json['unreadMessageCount'],
        json['unreadMessages'],
        json['messagesUnreadCount'],
        messagesMap['unreadCount'],
      ]),
      unreadNotificationCount: readInt([
        json['unreadNotificationCount'],
        json['unreadNotifications'],
        json['notificationsUnreadCount'],
        notificationsMap['unreadCount'],
      ]),
    );
  }
}

class HomeSummaryService {
  final Dio _dio;
  bool _isEndpointUnavailable = false;
  Future<HomeSummaryData?>? _inFlight;

  HomeSummaryService(this._dio);

  Future<HomeSummaryData?> getSummary() async {
    if (_isEndpointUnavailable) {
      return null;
    }

    final inFlight = _inFlight;
    if (inFlight != null) {
      return inFlight;
    }

    final future = _fetchSummary();
    _inFlight = future;
    try {
      return await future;
    } finally {
      _inFlight = null;
    }
  }

  Future<HomeSummaryData?> _fetchSummary() async {
    try {
      final response = await _dio.get('/api/home/summary');
      final payload = _extractPayload(response.data);
      if (payload == null) {
        return null;
      }
      return HomeSummaryData.fromJson(payload);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        _isEndpointUnavailable = true;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic>? _extractPayload(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      final data = raw['data'];
      if (data is Map<String, dynamic>) {
        return data;
      }
      return raw;
    }
    if (raw is Map) {
      final map = Map<String, dynamic>.from(raw);
      final data = map['data'];
      if (data is Map) {
        return Map<String, dynamic>.from(data);
      }
      return map;
    }
    return null;
  }
}
