import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../utils/app_logger.dart';

/// Arkaplan ses iletişimi için Android süreç koruma katmanı.
///
/// ### Çift Katman Koruma Stratejisi
///
/// **Katman 1 — Foreground Service**
/// AndroidManifest'te `android:stopWithTask="false"` + `android:exported="false"`
/// ile declare edilmiş bir foreground service başlatır. Bu sayede:
/// - Kullanıcı Recents'tan uygulamayı swipe'layıp kapattığında servis
///   yaşamaya devam eder (WhatsApp / Zoom davranışı).
/// - Diğer uygulamalar bu servise bind olamaz (güvenlik).
/// - Bildirim çubuğunda kalıcı "Sesli iletişim aktif" bildirimi gösterir.
///
/// **Katman 2 — PARTIAL_WAKE_LOCK**
/// Foreground service tek başına CPU'nun suspend/sleep'e geçmesini
/// engellemez. Ekran kapandığında kernel Timer'ları ve network I/O'yu
/// geciktirebilir (10–60 sn). Bu gecikme WebRTC ICE keepalive ve SignalR
/// ping paketlerinin zamanında gönderilememesine → bağlantı timeout'una
/// yol açar.
///
/// `PARTIAL_WAKE_LOCK` alarak CPU'nun uyanık kalmasını garantiliyoruz.
/// Wake lock process-scoped'dur: process sonlandığında OS otomatik serbest
/// bırakır, yani leak riski yoktur.
///
/// ### iOS
/// iOS'ta `flutter_background_service` kullanılmaz. Bunun yerine:
/// - `Info.plist`'de `audio` + `voip` background mode'ları,
/// - `AVAudioSession` category `playAndRecord` + `voiceChat` mode,
/// - `PKPushRegistry` (VoIP push) kullanılır.
/// Bu sınıf iOS'ta tüm çağrılar için no-op döner.
class AppBackgroundService {
  static const _channelId = 'moto_comm_foreground_service';
  static const _notificationId = 888;

  // ─────────────────────────────────────────────────────────────────────────
  // Public API
  // ─────────────────────────────────────────────────────────────────────────

  /// Foreground service konfigürasyonunu hazırlar.
  /// Uygulama başlangıcında tek kez, main isolate'den `runApp` öncesinde çağrılmalı.
  static Future<void> initialize() async {
    if (!Platform.isAndroid) return;

    final service = FlutterBackgroundService();

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: _onStart,
        autoStart: false,
        isForegroundMode: true,
        notificationChannelId: _channelId,
        initialNotificationTitle: 'Moto Comm',
        initialNotificationContent: 'Ses servisi başlatılıyor...',
        foregroundServiceNotificationId: _notificationId,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: _onIosForeground,
        onBackground: _onIosBackground,
      ),
    );
  }

  /// Foreground service'i başlatır ve PARTIAL_WAKE_LOCK alır.
  ///
  /// Main Flutter isolate'inden (intercom engine `start()` içi) çağrılmalı.
  /// İdempotent — zaten çalışıyorsa tekrar başlatmaz.
  static Future<void> start() async {
    if (!Platform.isAndroid) return;

    // ── Katman 1: Foreground Service ──────────────────────────────────────
    final service = FlutterBackgroundService();
    if (!await service.isRunning()) {
      AppLogger.info('BackgroundService ▶ Foreground service başlatılıyor...');
      service.startService();
    }

    // ── Katman 2: PARTIAL_WAKE_LOCK ───────────────────────────────────────
    // Ekran kapandığında CPU'nun uyanık kalmasını sağlar.
    // WebRTC ICE keepalive (~15 sn) ve SignalR server-ping (~15 sn)
    // zamanında iletilir; bağlantı timeout'a düşmez.
    try {
      final alreadyEnabled = await WakelockPlus.enabled;
      if (!alreadyEnabled) {
        await WakelockPlus.enable();
        AppLogger.info('BackgroundService ▶ PARTIAL_WAKE_LOCK alındı.');
      }
    } catch (e) {
      // Wake lock başarısız olursa servis yine de çalışır.
      AppLogger.warning('BackgroundService ⚠ Wake lock enable başarısız: $e');
    }
  }

  /// Foreground service'i durdurur ve PARTIAL_WAKE_LOCK'u serbest bırakır.
  ///
  /// Main Flutter isolate'inden (intercom engine `stop()` / `detachSession()` içi) çağrılmalı.
  /// İdempotent.
  static Future<void> stop() async {
    if (!Platform.isAndroid) return;

    // ── Katman 2: Wake lock'u önce serbest bırak ──────────────────────────
    // Servis kapanmadan önce kernel normal güç yönetimine dönebilsin.
    try {
      final isEnabled = await WakelockPlus.enabled;
      if (isEnabled) {
        await WakelockPlus.disable();
        AppLogger.info('BackgroundService ▶ PARTIAL_WAKE_LOCK serbest bırakıldı.');
      }
    } catch (e) {
      AppLogger.warning('BackgroundService ⚠ Wake lock disable başarısız: $e');
    }

    // ── Katman 1: Foreground Service'i durdur ────────────────────────────
    final service = FlutterBackgroundService();
    if (await service.isRunning()) {
      AppLogger.info('BackgroundService ▶ Foreground service durduruluyor...');
      service.invoke('stopService');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Background Isolate Entry Point
  // ─────────────────────────────────────────────────────────────────────────

  /// Android background service isolate'inin giriş noktası.
  ///
  /// Bu metot ana Flutter isolate'inden **ayrı** bir Dart isolate'inde koşar.
  /// Sorumluluğu: foreground notification'ı ayakta tutmak ve OEM'in
  /// servisi background'a indirmesini tespit edip geri almak.
  ///
  /// ⚠️ SignalR / WebRTC / LiveKit bu isolate'de çalışmaz; onlar main
  /// isolate'dedir. Gerçek audio işlemi wake lock sayesinde uyanık kalan
  /// (CPU-active) main thread'de devam eder.
  @pragma('vm:entry-point')
  static void _onStart(ServiceInstance service) async {
    DartPluginRegistrant.ensureInitialized();

    final notificationsPlugin = FlutterLocalNotificationsPlugin();

    // ── Kontrol event listener'ları ──────────────────────────────────────
    if (service is AndroidServiceInstance) {
      service.on('setAsForeground').listen((_) => service.setAsForegroundService());
      service.on('setAsBackground').listen((_) => service.setAsBackgroundService());
    }
    service.on('stopService').listen((_) => service.stopSelf());

    // ── Foreground notification kanalı ve bildirimi ───────────────────────
    // Importance.low  → görünür ama ses/titreşim yok.
    // enableVibration: false, playSound: false → arka planda sessiz.
    // NOT: Foreground service bildirimleri Android tarafından otomatik
    //   "ongoing" (kapat düğmesi yok) yapılır; importance bunu etkilemez.
    if (service is AndroidServiceInstance) {
      await notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(
            const AndroidNotificationChannel(
              _channelId,
              'Moto Comm Ses Servisi',
              description:
                  'Sesli iletişimi arkaplanda ve ekran kapalıyken aktif tutar.',
              importance: Importance.low,
              enableVibration: false,
              playSound: false,
            ),
          );

      await service.setForegroundNotificationInfo(
        title: 'Moto Comm',
        content: 'Sesli iletişim arkaplanda aktif',
      );
    }

    // ── Heartbeat loop ───────────────────────────────────────────────────
    // Her 30 sn'de bir servisin foreground önceliğini doğrula.
    // Bazı OEM'ler (Xiaomi MIUI, Huawei EMUI) foreground servisi sessizce
    // background'a demote etmeye çalışır; bunu tespit edip geri alıyoruz.
    Timer.periodic(const Duration(seconds: 30), (timer) async {
      if (service is AndroidServiceInstance) {
        final isFg = await service.isForegroundService();
        if (!isFg) {
          AppLogger.warning(
            'BackgroundService ⚠ OEM foreground önceliğini kaldırdı — yeniden talep ediliyor.',
          );
          service.setAsForegroundService();
        }
      }
    });

    AppLogger.info('BackgroundService ▶ Foreground service isolate hazır.');
  }

  // ─────────────────────────────────────────────────────────────────────────
  // iOS Stubs (IosConfiguration imzası için gerekli — işlevsizdir)
  // ─────────────────────────────────────────────────────────────────────────

  @pragma('vm:entry-point')
  static bool _onIosForeground(ServiceInstance service) => true;

  @pragma('vm:entry-point')
  static bool _onIosBackground(ServiceInstance service) => true;
}
