import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../utils/app_logger.dart';

/// Manages background execution for Android to prevent OS kills.
/// On iOS, we rely on `audio` background mode and active `AVAudioSession`.
class AppBackgroundService {
  static const notificationChannelId = 'moto_comm_foreground_service';
  static const notificationId = 888;

  static Future<void> initialize() async {
    if (!Platform.isAndroid) return;

    final service = FlutterBackgroundService();

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        // This will be executed in the isolate
        onStart: _onStart,
        autoStart: false,
        isForegroundMode: true,
        notificationChannelId: notificationChannelId,
        initialNotificationTitle: 'Moto Comm',
        initialNotificationContent: 'Ses servisi aktif',
        foregroundServiceNotificationId: notificationId,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: _onIosForeground,
        onBackground: _onIosBackground,
      ),
    );
  }

  static Future<void> start() async {
    if (!Platform.isAndroid) return;

    final service = FlutterBackgroundService();
    if (!await service.isRunning()) {
      AppLogger.info("BackgroundService: Starting...");
      service.startService();
    }
  }

  static Future<void> stop() async {
    if (!Platform.isAndroid) return;

    final service = FlutterBackgroundService();
    if (await service.isRunning()) {
      AppLogger.info("BackgroundService: Stopping...");
      service.invoke("stopService");
    }
  }

  // --- Isolate Entry Point ---

  @pragma('vm:entry-point')
  static void _onStart(ServiceInstance service) async {
    DartPluginRegistrant.ensureInitialized();

    final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    if (service is AndroidServiceInstance) {
      service.on('setAsForeground').listen((event) {
        service.setAsForegroundService();
      });

      service.on('setAsBackground').listen((event) {
        service.setAsBackgroundService();
      });
    }

    service.on('stopService').listen((event) {
      service.stopSelf();
    });

    // Bring to foreground immediately
    if (service is AndroidServiceInstance) {
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(
            const AndroidNotificationChannel(
              notificationChannelId,
              'Moto Comm Background Service',
              description: 'Keeps audio active in background',
              importance: Importance.low,
            ),
          );

      await service.setForegroundNotificationInfo(
        title: "Moto Comm",
        content: "Sesli iletişim arkaplanda aktif",
      );
    }

    // Keep alive loop (optional, but good for debug)
    Timer.periodic(const Duration(seconds: 30), (timer) async {
      if (service is AndroidServiceInstance) {
        if (await service.isForegroundService()) {
          // We can update notification here if we want dynamic content
          // service.setForegroundNotificationInfo(...)
        }
      }
    });

    AppLogger.info("BackgroundService: Started in Isolate");
  }

  // iOS Specifics (Unused but required by config signature)
  @pragma('vm:entry-point')
  static bool _onIosForeground(ServiceInstance service) {
    return true;
  }

  @pragma('vm:entry-point')
  static bool _onIosBackground(ServiceInstance service) {
    return true;
  }
}
