import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:geolocator/geolocator.dart';
import 'package:path_provider/path_provider.dart';

import '../../domain/entities/ride_entity.dart';
import '../../domain/services/ride_recording_service.dart';

class RideRecordingServiceImpl implements RideRecordingService {
  static const _bufferFileName = 'ride_buffer.json';
  static const _minAccuracyMeters = 50.0;
  static const _minDistanceMeters = 3.0;
  static const _flushIntervalSeconds = 30;
  static const _flushEveryNPoints = 20;

  final _pointController = StreamController<RidePoint>.broadcast();
  StreamSubscription<Position>? _positionSub;
  Timer? _flushTimer;
  final List<RidePoint> _points = [];
  DateTime? _startedAt;
  RidePoint? _lastPoint;
  File? _bufferFile;

  @override
  Stream<RidePoint> get pointStream => _pointController.stream;

  @override
  bool get isRecording => _positionSub != null;

  @override
  Future<void> start() async {
    if (isRecording) return;
    _points.clear();
    _lastPoint = null;
    _startedAt = DateTime.now().toUtc();

    final dir = await getApplicationSupportDirectory();
    _bufferFile = File('${dir.path}/$_bufferFileName');
    await _flushBuffer();

    final LocationSettings settings;
    if (Platform.isAndroid) {
      settings = AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationTitle: 'Rota Kaydı',
          notificationText: 'Sürüşünüz kaydediliyor...',
          enableWakeLock: true,
        ),
      );
    } else {
      settings = AppleSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
        activityType: ActivityType.automotiveNavigation,
        pauseLocationUpdatesAutomatically: false,
        allowBackgroundLocationUpdates: true,
      );
    }

    _positionSub = Geolocator.getPositionStream(locationSettings: settings)
        .listen(_onPosition, onError: (_) {});

    _flushTimer = Timer.periodic(
      const Duration(seconds: _flushIntervalSeconds),
      (_) => _flushBuffer(),
    );
  }

  void _onPosition(Position pos) {
    if (pos.accuracy > _minAccuracyMeters) return;

    // Cached/buffered GPS position from before start() was called — discard.
    final ts = pos.timestamp.toUtc();
    if (_startedAt != null && ts.isBefore(_startedAt!)) return;

    final point = RidePoint(
      latitude: pos.latitude,
      longitude: pos.longitude,
      timestamp: ts,
      speedKmh: pos.speed < 0 ? null : pos.speed * 3.6,
    );

    if (_lastPoint != null &&
        _haversine(_lastPoint!, point) < _minDistanceMeters) {
      return;
    }

    _lastPoint = point;
    _points.add(point);
    _pointController.add(point);

    if (_points.length % _flushEveryNPoints == 0) _flushBuffer();
  }

  @override
  Future<RideEntity?> stop() async {
    await _positionSub?.cancel();
    _positionSub = null;
    _flushTimer?.cancel();
    _flushTimer = null;

    if (_points.isEmpty) {
      try {
        await _bufferFile?.delete();
      } catch (_) {}
      _bufferFile = null;
      return null;
    }

    final ride = _buildEntity();
    try {
      await _bufferFile?.delete();
    } catch (_) {}
    _bufferFile = null;
    _points.clear();
    _startedAt = null;
    _lastPoint = null;
    return ride;
  }

  @override
  Future<RideEntity?> recoverIfNeeded() async {
    final dir = await getApplicationSupportDirectory();
    final file = File('${dir.path}/$_bufferFileName');
    if (!await file.exists()) return null;

    try {
      final raw = await file.readAsString();
      if (raw.trim().isEmpty) {
        await file.delete();
        return null;
      }
      final data = jsonDecode(raw) as Map<String, dynamic>;
      final rawPoints = data['points'] as List<dynamic>? ?? [];
      if (rawPoints.isEmpty) {
        await file.delete();
        return null;
      }

      _points.clear();
      for (final p in rawPoints) {
        final m = p as Map<String, dynamic>;
        _points.add(RidePoint(
          latitude: (m['lat'] as num).toDouble(),
          longitude: (m['lng'] as num).toDouble(),
          timestamp: DateTime.parse(m['ts'] as String),
          speedKmh: (m['spd'] as num?)?.toDouble(),
        ));
      }

      _startedAt = data['startedAt'] != null
          ? DateTime.parse(data['startedAt'] as String)
          : _points.first.timestamp;
      _bufferFile = file;

      return _buildEntity();
    } catch (_) {
      try {
        await file.delete();
      } catch (_) {}
      return null;
    }
  }

  @override
  Future<void> discardRecovery() async {
    try {
      await _bufferFile?.delete();
    } catch (_) {}
    _bufferFile = null;
    _points.clear();
    _startedAt = null;
    _lastPoint = null;
  }

  RideEntity _buildEntity() {
    final start = (_startedAt ?? _points.first.timestamp).toUtc();
    final end = _points.last.timestamp.toUtc();
    final durationSec = end.difference(start).inSeconds.clamp(0, 999999);

    double totalKm = 0;
    double totalSpeed = 0;
    double maxSpeed = 0;
    int speedCount = 0;

    for (int i = 1; i < _points.length; i++) {
      totalKm += _haversine(_points[i - 1], _points[i]) / 1000;
    }
    for (final p in _points) {
      if (p.speedKmh != null) {
        totalSpeed += p.speedKmh!;
        speedCount++;
        if (p.speedKmh! > maxSpeed) maxSpeed = p.speedKmh!;
      }
    }

    final startCity = _points.isNotEmpty
        ? '${_points.first.latitude.toStringAsFixed(3)}, ${_points.first.longitude.toStringAsFixed(3)}'
        : null;

    return RideEntity(
      title:
          'Sürüş ${_formatDate(start)}',
      startedAt: start,
      endedAt: end,
      distanceKm: double.parse(totalKm.toStringAsFixed(2)),
      durationSeconds: durationSec,
      avgSpeedKmh:
          speedCount > 0 ? double.parse((totalSpeed / speedCount).toStringAsFixed(1)) : null,
      maxSpeedKmh: maxSpeed > 0 ? double.parse(maxSpeed.toStringAsFixed(1)) : null,
      startCity: startCity,
      points: List.unmodifiable(_points),
    );
  }

  Future<void> _flushBuffer() async {
    final file = _bufferFile;
    if (file == null) return;
    try {
      final data = {
        'startedAt': _startedAt?.toIso8601String(),
        'points': _points
            .map((p) => {
                  'lat': p.latitude,
                  'lng': p.longitude,
                  'ts': p.timestamp.toIso8601String(),
                  if (p.speedKmh != null) 'spd': p.speedKmh,
                })
            .toList(),
      };
      await file.writeAsString(jsonEncode(data));
    } catch (_) {}
  }

  static double _haversine(RidePoint a, RidePoint b) {
    const r = 6371000.0;
    final dLat = _rad(b.latitude - a.latitude);
    final dLon = _rad(b.longitude - a.longitude);
    final sinDLat = sin(dLat / 2);
    final sinDLon = sin(dLon / 2);
    final h =
        sinDLat * sinDLat +
        cos(_rad(a.latitude)) * cos(_rad(b.latitude)) * sinDLon * sinDLon;
    return 2 * r * asin(sqrt(h));
  }

  static double _rad(double deg) => deg * pi / 180;

  static String _formatDate(DateTime dt) {
    final d = dt.toLocal();
    String pad(int n) => n.toString().padLeft(2, '0');
    return '${pad(d.day)}.${pad(d.month)}.${d.year} ${pad(d.hour)}:${pad(d.minute)}';
  }
}
