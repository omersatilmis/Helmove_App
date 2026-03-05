import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../di/background_injection.dart';
import '../utils/app_logger.dart';

@pragma('vm:entry-point')
class AppBackgroundService {
  static const String _channelId = 'moto_comm_foreground_service';
  static const String _channelName = 'Moto Comm Foreground Service';
  static const String _channelDescription =
      'Keeps voice communication active in background.';
  static const int _notificationId = 888;
  static bool _isConfigured = false;
  static Completer<void>? _initializeCompleter;
  static Completer<void>? _startCompleter;

  static bool get _isMainIsolate => RootIsolateToken.instance != null;

  /// Configure background service. Must run on UI isolate.
  static Future<void> initialize() async {
    if (!Platform.isAndroid) return;
    if (!_isMainIsolate) {
      AppLogger.warning(
        'AppBackgroundService.initialize ignored: not on main isolate.',
      );
      return;
    }
    if (_isConfigured) {
      return;
    }
    if (_initializeCompleter != null) {
      return _initializeCompleter!.future;
    }

    final completer = Completer<void>();
    _initializeCompleter = completer;

    try {
      final service = FlutterBackgroundService();
      final localNotifications = FlutterLocalNotificationsPlugin();

      final androidNotifications = localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      await androidNotifications?.createNotificationChannel(
        const AndroidNotificationChannel(
          _channelId,
          _channelName,
          description: _channelDescription,
          importance: Importance.low,
        ),
      );

      await service.configure(
        androidConfiguration: AndroidConfiguration(
          onStart: _onStart,
          autoStart: false,
          isForegroundMode: true,
          notificationChannelId: _channelId,
          initialNotificationTitle: 'Moto Comm Active',
          initialNotificationContent: 'Background communication is starting...',
          foregroundServiceNotificationId: _notificationId,
          foregroundServiceTypes: const [AndroidForegroundType.microphone],
        ),
        iosConfiguration: IosConfiguration(
          autoStart: false,
          onForeground: _onIosForeground,
          onBackground: _onIosBackground,
        ),
      );

      _isConfigured = true;
      completer.complete();
    } catch (e, st) {
      completer.completeError(e, st);
      rethrow;
    } finally {
      _initializeCompleter = null;
    }
  }

  /// Start foreground service and acquire wakelock. Must run on UI isolate.
  static Future<void> start() async {
    if (!Platform.isAndroid) return;
    if (!_isMainIsolate) {
      AppLogger.warning(
        'AppBackgroundService.start ignored: not on main isolate.',
      );
      return;
    }
    if (_startCompleter != null) {
      return _startCompleter!.future;
    }

    final completer = Completer<void>();
    _startCompleter = completer;
    try {
      if (!_isConfigured) {
        await initialize();
      }

      final service = FlutterBackgroundService();
      if (!await service.isRunning()) {
        AppLogger.info('BackgroundService: starting foreground service.');
        await service.startService();
      }

      try {
        final alreadyEnabled = await WakelockPlus.enabled;
        if (!alreadyEnabled) {
          await WakelockPlus.enable();
          AppLogger.info('BackgroundService: PARTIAL_WAKE_LOCK acquired.');
        }
      } catch (e) {
        AppLogger.warning('BackgroundService: wakelock enable failed: $e');
      }

      completer.complete();
    } catch (e, st) {
      completer.completeError(e, st);
      rethrow;
    } finally {
      _startCompleter = null;
    }
  }

  /// Stop foreground service and release wakelock. Must run on UI isolate.
  static Future<void> stop() async {
    if (!Platform.isAndroid) return;
    if (!_isMainIsolate) {
      AppLogger.warning(
        'AppBackgroundService.stop ignored: not on main isolate.',
      );
      return;
    }

    try {
      final isEnabled = await WakelockPlus.enabled;
      if (isEnabled) {
        await WakelockPlus.disable();
        AppLogger.info('BackgroundService: PARTIAL_WAKE_LOCK released.');
      }
    } catch (e) {
      AppLogger.warning('BackgroundService: wakelock disable failed: $e');
    }

    final service = FlutterBackgroundService();
    if (await service.isRunning()) {
      AppLogger.info('BackgroundService: stopping foreground service.');
      service.invoke('stopService');
    }
  }

  /// Background isolate entrypoint. Use only ServiceInstance here.
  @pragma('vm:entry-point')
  static void _onStart(ServiceInstance service) async {
    try {
      await initBackgroundDi();
    } catch (e) {
      AppLogger.warning('BackgroundService: background DI init failed: $e');
    }

    if (service is AndroidServiceInstance) {
      service.on('setAsForeground').listen((_) {
        service.setAsForegroundService();
      });
      service.on('setAsBackground').listen((_) {
        service.setAsBackgroundService();
      });
    }

    service.on('stopService').listen((_) {
      service.stopSelf();
    });

    if (service is AndroidServiceInstance) {
      service.setForegroundNotificationInfo(
        title: 'Moto Comm',
        content: 'Sesli iletisim arkaplanda aktif',
      );
    }

    Timer.periodic(const Duration(seconds: 30), (_) async {
      if (service is AndroidServiceInstance) {
        final isForeground = await service.isForegroundService();
        if (!isForeground) {
          AppLogger.warning(
            'BackgroundService: foreground priority dropped, requesting again.',
          );
          service.setAsForegroundService();
        }
      }
    });

    AppLogger.info('BackgroundService: background isolate ready.');
  }

  @pragma('vm:entry-point')
  static bool _onIosForeground(ServiceInstance service) => true;

  @pragma('vm:entry-point')
  static bool _onIosBackground(ServiceInstance service) => true;
}
