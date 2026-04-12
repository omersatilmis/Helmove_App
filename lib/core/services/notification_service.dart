import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;
import 'package:go_router/go_router.dart';
import '../utils/app_logger.dart';
import '../navigation/navigator_keys.dart';
import 'callkit_incoming_service.dart';
import 'sos_alert_listener_service.dart';

// Background message handler must be a top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other services here, make sure they are initialized
  AppLogger.info('Handling a background message: ${message.messageId}');
}

class NotificationService {
  final CallKitIncomingService _callKitIncomingService;
  final SosAlertListenerService _sosAlertListenerService;
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  bool _isInitialized = false;
  Future<void>? _initializeFuture;

  NotificationService(
    this._callKitIncomingService,
    this._sosAlertListenerService,
  );

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
      // 1. Request Permissions
      NotificationSettings settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      AppLogger.info('User granted permission: ${settings.authorizationStatus}');

      // 2. Initialize CallKit and SOS
      await _callKitIncomingService.initialize();
      _sosAlertListenerService.start();

      // 3. Initialize Local Notifications (for Foreground)
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const DarwinInitializationSettings iosSettings = DarwinInitializationSettings();
      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _localNotifications.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse details) {
          // Handle notification click when foreground
          if (details.payload != null) {
            // Logic for handling payload from local notification tap if needed
          }
        },
      );

      // 4. Foreground Message Listener
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        AppLogger.info('Got a message whilst in the foreground!');
        AppLogger.info('Message data: ${message.data}');

        if (message.notification != null) {
          AppLogger.info('Message also contained a notification: ${message.notification?.title}');
          _showLocalNotification(message);
        }

        _handleIncomingPayload(message.data, source: 'foreground');
      });

      // 5. Message Opened App Listener (Background -> Foreground)
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        AppLogger.info('A new onMessageOpenedApp event was published!');
        _handleIncomingPayload(message.data, source: 'click');
      });

      // 6. Initial Message (Terminated -> Foreground)
      RemoteMessage? initialMessage = await _fcm.getInitialMessage();
      if (initialMessage != null) {
        AppLogger.info('Terminated state initial message detected');
        _handleIncomingPayload(initialMessage.data, source: 'initial');
      }

      // 7. Get FCM Token (APNS token may not be ready yet on iOS)
      String? token = await _safeGetFcmToken();
      if (token != null) {
        AppLogger.info('FCM Token: $token');
      }

    } catch (e, st) {
      _isInitialized = false;
      AppLogger.error('NotificationService: initialize error', e, st);
    }
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      importance: Importance.max,
      priority: Priority.high,
    );
    const NotificationDetails platformDetails = NotificationDetails(android: androidDetails);

    await _localNotifications.show(
      id: message.hashCode,
      title: message.notification?.title,
      body: message.notification?.body,
      notificationDetails: platformDetails,
      payload: message.data.toString(),
    );
  }

  Future<void> login(String userId) async {
    try {
      String? token = await _safeGetFcmToken();
      if (token != null) {
        AppLogger.info('NotificationService: login - syncing FCM token for user $userId');
      }

      final voipToken = await _callKitIncomingService.getVoipToken();
      if (voipToken != null) {
        AppLogger.info('NotificationService: VoIP token ready len=${voipToken.length}');
      }
    } catch (e, st) {
      AppLogger.error('NotificationService: login error', e, st);
    }
  }

  Future<String?> _safeGetFcmToken() async {
    try {
      return await _fcm.getToken();
    } on FirebaseException catch (e, st) {
      final isApnsNotReady = e.code == 'apns-token-not-set';
      final isApplePlatform = !kIsWeb && (Platform.isIOS || Platform.isMacOS);
      if (isApnsNotReady && isApplePlatform) {
        AppLogger.warning(
          'NotificationService: APNS token not ready yet. FCM token will be retried later.',
        );
        return null;
      }
      AppLogger.error('NotificationService: getToken error', e, st);
      return null;
    } catch (e, st) {
      AppLogger.error('NotificationService: getToken error', e, st);
      return null;
    }
  }

  Future<void> logout() async {
    try {
      AppLogger.info('NotificationService: logout - should unregister FCM token on backend');
    } catch (e, st) {
      AppLogger.error('NotificationService: logout error', e, st);
    }
  }

  Future<void> _handleIncomingPayload(Map<String, dynamic> data, {required String source}) async {
    final callHandled = await _handleIncomingCallPayload(data, source: source);
    if (!callHandled) {
      final sosHandled = await _handleSosPayload(data, source: source);
      if (!sosHandled) {
        await _handleGenericNavigation(data, source: source);
      }
    }
  }

  Future<void> _handleGenericNavigation(Map<String, dynamic> data, {required String source}) async {
    final kind = data['kind'] as String? ?? data['NotificationType']?.toString();
    if (kind == null) return;

    final navigator = rootNavigatorKey.currentState;
    if (navigator == null) {
      AppLogger.warning('NotificationService: Navigator state is null. Navigation deferred.');
      return;
    }

    final context = navigator.context;

    if (kind == 'chat' || kind == '14') {
      final senderId = data['senderId'] ?? data['SenderId'];
      final firstName = data['firstName'] ?? data['FirstName'] ?? '';
      final lastName = data['lastName'] ?? data['LastName'] ?? '';
      final username = data['username'] ?? data['Username'] ?? '';
      final profileImageUrl = data['profileImageUrl'] ?? data['ProfileImageUrl'] ?? '';

      if (senderId != null) {
        GoRouter.of(context).push(
          '/chat/$senderId?firstName=$firstName&lastName=$lastName&username=$username&profileImageUrl=$profileImageUrl',
        );
      }
    } else if (kind == 'follow' || kind == '2') {
      final userId = data['userId'] ?? data['UserId'];
      if (userId != null) {
        GoRouter.of(context).push('/profile/$userId');
      }
    } else if (kind == 'group_invite' || kind == '4') {
      final rideId = data['rideId'] ?? data['RideId'];
      if (rideId != null) {
        GoRouter.of(context).push('/communication/group-page/$rideId');
      }
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

  Future<bool> _handleSosPayload(dynamic raw, {required String source}) async {
    final handled = await _sosAlertListenerService.showFromPushData(raw);
    if (handled) {
      AppLogger.warning(
        'NotificationService: sos_alert detected source=$source',
      );
    }
    return handled;
  }

  static Future<void> setupBackgroundHandler() async {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }
}
