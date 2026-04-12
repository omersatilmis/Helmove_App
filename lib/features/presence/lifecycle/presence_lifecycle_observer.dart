import 'package:flutter/widgets.dart';
import 'package:signalr_netcore/signalr_client.dart';

import '../../../core/services/message_signalr_service.dart';
import '../../../core/utils/app_logger.dart';
import '../services/presence_controller.dart';

/// Uygulama yaşam döngüsünü dinleyerek presence sistemini yönetir.
///
/// Kullanım — main.dart veya root widget'ın initState'inde:
/// ```dart
/// _observer = PresenceLifecycleObserver(
///   presenceController: sl<PresenceController>(),
///   signalRService: sl<MessageSignalRService>(),
/// );
/// WidgetsBinding.instance.addObserver(_observer);
/// ```
///
/// dispose'da:
/// ```dart
/// WidgetsBinding.instance.removeObserver(_observer);
/// ```
class PresenceLifecycleObserver extends WidgetsBindingObserver {
  final PresenceController _presenceController;
  final MessageSignalRService _signalRService;

  PresenceLifecycleObserver({
    required PresenceController presenceController,
    required MessageSignalRService signalRService,
  })  : _presenceController = presenceController,
        _signalRService = signalRService;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _handleForeground();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        _handleBackground();
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        // iOS'ta kısa inactive geçişlerinde bir şey yapmıyoruz.
        break;
    }
  }

  Future<void> _handleForeground() async {
    AppLogger.info("PresenceLifecycle: Foreground'a dönüldü");

    // SignalR bağlantısı kopuksa yeniden başlat
    if (!_signalRService.isConnected) {
      AppLogger.info("PresenceLifecycle: SignalR yeniden başlatılıyor...");
      await _signalRService.init();
    }

    // Bağlantı başarılıysa veya zaten bağlıysa heartbeat'i yeniden başlat
    final state = await _waitForConnection();
    if (state == HubConnectionState.Connected) {
      _presenceController.onForeground();
    }
  }

  void _handleBackground() {
    AppLogger.info("PresenceLifecycle: Background'a geçildi");
    _presenceController.onBackground();
    // Not: SignalR bağlantısı kasıtlı kapatılmıyor.
    // Sunucu 45s TTL ile offline işaretler; FCM push bildirim almaya devam eder.
  }

  /// Bağlantının kurulmasını kısa süre bekler.
  /// `withAutomaticReconnect` zaten retry yapıyor, sadece anlık durumu dönderir.
  Future<HubConnectionState> _waitForConnection() async {
    if (_signalRService.isConnected) return HubConnectionState.Connected;

    // En fazla 3 saniye bekle
    for (var i = 0; i < 6; i++) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (_signalRService.isConnected) return HubConnectionState.Connected;
    }

    return HubConnectionState.Disconnected;
  }
}
