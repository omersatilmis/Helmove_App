import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import '../../app/app_router.dart';
import '../../features/communication/presentation/pages/sos_alert_page.dart';
import '../utils/app_logger.dart';
import 'models/signalr_payloads.dart';
import 'signalr_service.dart';

class SosAlertListenerService {
  final SignalRService _signalRService;
  StreamSubscription<SosAlertPayload>? _signalRSub;
  bool _started = false;
  bool _isOpening = false;
  final Map<String, DateTime> _dedupCache = <String, DateTime>{};
  static const Duration _dedupWindow = Duration(seconds: 10);

  SosAlertListenerService(this._signalRService);

  void start() {
    if (_started) return;
    _started = true;
    _signalRSub = _signalRService.sosAlertStream.listen(_handleSosPayload);
  }

  Future<bool> showFromPushData(dynamic rawData) async {
    final map = _normalizeMap(rawData);
    if (map == null) return false;

    final kind = (map['kind'] ?? map['notificationType'] ?? map['type'])
        ?.toString()
        .trim()
        .toLowerCase();
    if (kind != 'sos_alert') return false;

    final payload = SosAlertPayload.tryParse(map);
    if (payload == null) return false;
    _handleSosPayload(payload);
    return true;
  }

  void _handleSosPayload(SosAlertPayload payload) {
    if (!payload.isValid) return;
    if (_isDuplicate(payload)) return;

    final navigator = rootNavigatorKey.currentState;
    if (navigator == null) {
      AppLogger.warning(
        'SosAlertListenerService: root navigator not ready, alert ignored.',
      );
      return;
    }
    if (_isOpening) return;

    _isOpening = true;
    navigator
        .push(
          MaterialPageRoute<void>(
            builder: (_) => SosAlertPage(alert: payload),
            fullscreenDialog: true,
          ),
        )
        .whenComplete(() {
          _isOpening = false;
        });
  }

  bool _isDuplicate(SosAlertPayload payload) {
    final now = DateTime.now().toUtc();
    _dedupCache.removeWhere(
      (_, at) => now.difference(at) > _dedupWindow + const Duration(seconds: 2),
    );

    final key =
        '${payload.groupRideId}:${payload.senderId}:${payload.sentAt.toUtc().toIso8601String()}';
    final previous = _dedupCache[key];
    if (previous != null && now.difference(previous) < _dedupWindow) {
      return true;
    }
    _dedupCache[key] = now;
    return false;
  }

  Map<String, dynamic>? _normalizeMap(dynamic raw) {
    if (raw == null) return null;
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    if (raw is String) {
      final text = raw.trim();
      if (text.isEmpty) return null;
      try {
        final decoded = jsonDecode(text);
        if (decoded is Map<String, dynamic>) return decoded;
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  Future<void> dispose() async {
    await _signalRSub?.cancel();
    _signalRSub = null;
    _started = false;
  }
}
