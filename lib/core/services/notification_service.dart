import 'package:onesignal_flutter/onesignal_flutter.dart';

import '../utils/app_logger.dart';
import 'callkit_incoming_service.dart';

class NotificationService {
  static const String _appId = '826a8fdc-3290-4a00-a14b-74a4c6e8ac20';

  final CallKitIncomingService _callKitIncomingService;
  bool _isInitialized = false;
  Future<void>? _initializeFuture;

  NotificationService(this._callKitIncomingService);

  Future<void> ensureInitialized() async {
    if (_isInitialized) return;
    if (_initializeFuture != null) return _initializeFuture!;

    final future = _doInitialize();
    _initializeFuture = future;
    try {
      await future;
    } finally {
      _initializeFuture = null;
    }
  }

  Future<void> initialize() async {
    await ensureInitialized();
  }

  Future<void> _doInitialize() async {
    _isInitialized = true;
    try {
      OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
      OneSignal.initialize(_appId);

      await _callKitIncomingService.initialize();

      // [FIX] Permission Centralization:
      // Don't request here. HomePage will handle it.
      // final permission = await OneSignal.Notifications.requestPermission(true);
      // AppLogger.info('NotificationService: permission=$permission');

      OneSignal.Notifications.addClickListener((event) async {
        final data = event.notification.additionalData;
        AppLogger.info(
          'NotificationService: click payloadType=${data.runtimeType} payload=$data',
        );

        await _handleIncomingCallPayload(data, source: 'click');
      });

      OneSignal.Notifications.addForegroundWillDisplayListener((event) async {
        final data = event.notification.additionalData;
        AppLogger.info(
          'NotificationService: foreground payloadType=${data.runtimeType} payload=$data',
        );

        final handled = await _handleIncomingCallPayload(
          data,
          source: 'foreground',
        );
        if (handled) {
          event.preventDefault();
        }
      });
    } catch (e, st) {
      _isInitialized = false;
      AppLogger.error('NotificationService: initialize error', e, st);
    }
  }

  Future<void> login(String userId) async {
    try {
      await OneSignal.login(userId);

      final voipToken = await _callKitIncomingService.getVoipToken();
      if (voipToken != null) {
        AppLogger.info(
          'NotificationService: VoIP token ready len=${voipToken.length}',
        );
      }
    } catch (e, st) {
      AppLogger.error('NotificationService: login error', e, st);
    }
  }

  Future<void> logout() async {
    try {
      await OneSignal.logout();
    } catch (e, st) {
      AppLogger.error('NotificationService: logout error', e, st);
    }
  }

  Future<bool> _handleIncomingCallPayload(
    dynamic raw, {
    required String source,
  }) async {
    final payload = CallInvitePayload.tryParse(raw);
    if (payload == null) {
      return false;
    }

    AppLogger.info(
      'NotificationService: incoming_call detected source=$source callerId=${payload.callerId} callId=${payload.callId ?? 0}',
    );

    await _callKitIncomingService.showIncomingCall(payload);
    return true;
  }
}
