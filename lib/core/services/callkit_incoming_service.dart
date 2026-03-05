import 'dart:async';
import 'dart:convert';

import 'package:flutter_callkit_incoming/entities/android_params.dart';
import 'package:flutter_callkit_incoming/entities/call_event.dart';
import 'package:flutter_callkit_incoming/entities/call_kit_params.dart';
import 'package:flutter_callkit_incoming/entities/ios_params.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:uuid/uuid.dart';

import '../utils/app_logger.dart';

enum CallKitActionType {
  incoming,
  accepted,
  declined,
  ended,
  timeout,
  connected,
  callback,
  devicePushTokenUpdated,
  unknown,
}

class CallInvitePayload {
  final String callKitId;
  final int callerId;
  final String callerDisplayName;
  final int? callId;

  const CallInvitePayload({
    required this.callKitId,
    required this.callerId,
    required this.callerDisplayName,
    this.callId,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'callKitId': callKitId,
      'callerId': callerId,
      'callerDisplayName': callerDisplayName,
      if (callId != null) 'callId': callId,
      'kind': 'incoming_call',
    };
  }

  static CallInvitePayload? tryParse(dynamic raw) {
    final map = _normalizeMap(raw);
    if (map == null) return null;

    final kind = (map['kind'] ?? map['notificationType'] ?? map['type'])
        ?.toString()
        .trim()
        .toLowerCase();
    if (kind != null &&
        kind.isNotEmpty &&
        kind != 'incoming_call' &&
        kind != 'call_invite') {
      return null;
    }

    final callerId = _toInt(
      map['callerId'] ??
          map['fromUserId'] ??
          map['actorId'] ??
          map['userId'] ??
          map['fromId'],
    );
    if (callerId == null || callerId <= 0) return null;

    final displayName =
        (map['callerDisplayName'] ??
                map['callerName'] ??
                map['nameCaller'] ??
                map['fromDisplayName'] ??
                map['title'])
            ?.toString()
            .trim() ??
        '';

    final callKitIdRaw = (map['callKitId'] ?? map['id'])?.toString().trim();
    final callKitId = (callKitIdRaw == null || callKitIdRaw.isEmpty)
        ? const Uuid().v4()
        : callKitIdRaw;

    return CallInvitePayload(
      callKitId: callKitId,
      callerId: callerId,
      callerDisplayName: displayName.isEmpty
          ? 'Bilinmeyen kullanici'
          : displayName,
      callId: _toInt(map['callId']),
    );
  }

  static Map<String, dynamic>? _normalizeMap(dynamic raw) {
    if (raw == null) return null;
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    if (raw is String) {
      final trimmed = raw.trim();
      if (trimmed.isEmpty) return null;
      try {
        final decoded = jsonDecode(trimmed);
        if (decoded is Map<String, dynamic>) return decoded;
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  static int? _toInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '');
  }
}

class CallKitAction {
  final CallKitActionType type;
  final CallInvitePayload? payload;
  final Map<String, dynamic> rawBody;
  final Event event;

  const CallKitAction({
    required this.type,
    required this.payload,
    required this.rawBody,
    required this.event,
  });
}

class CallKitIncomingService {
  final _uuid = const Uuid();
  final _actionController = StreamController<CallKitAction>.broadcast();
  DateTime? _suppressEndedEventsUntilUtc;
  static const Duration _endedSuppressionWindow = Duration(seconds: 2);

  StreamSubscription<CallEvent?>? _eventSubscription;
  bool _initialized = false;

  Stream<CallKitAction> get actionStream => _actionController.stream;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    _eventSubscription = FlutterCallkitIncoming.onEvent.listen(
      (event) {
        if (event == null) return;

        final body = event.body is Map
            ? Map<String, dynamic>.from(event.body as Map)
            : <String, dynamic>{};
        final extra = body['extra'];
        final payload =
            CallInvitePayload.tryParse(extra) ??
            CallInvitePayload.tryParse(body);

        final action = CallKitAction(
          type: _mapEventType(event.event),
          payload: payload,
          rawBody: body,
          event: event.event,
        );

        // App'in kendi endCall/endAllCalls çağrılarından hemen sonra gelen
        // native "ended" callback'i tekrar CallHangUp zinciri başlatmasın.
        if (action.type == CallKitActionType.ended && _isEndedSuppressed()) {
          AppLogger.info('CallKit: Suppressed programmatic ended callback.');
          return;
        }
        _actionController.add(action);
      },
      onError: (Object error, StackTrace stackTrace) {
        AppLogger.error('CallKit: Event stream error', error, stackTrace);
      },
    );

    // [FIX] Permission Centralization:
    // Don't request permissions here. It causes prompts on Login Screen.
    // Moved to HomePage -> PermissionsService logic if needed,
    // or simply relied on permission_handler's Permission.notification.
    // await _requestAndroidPermissions();
  }

  // Public method to be called from PermissionsService or HomePage if needed
  Future<void> requestPermissions() async {
    await _requestAndroidPermissions();
  }

  Future<void> showIncomingCall(CallInvitePayload payload) async {
    final params = CallKitParams(
      id: payload.callKitId,
      nameCaller: payload.callerDisplayName,
      appName: 'Moto Comm',
      handle: payload.callerDisplayName,
      type: 0,
      duration: 35000,
      textAccept: 'Kabul Et',
      textDecline: 'Reddet',
      extra: payload.toMap(),
      android: const AndroidParams(
        isCustomNotification: true,
        isCustomSmallExNotification: true,
        isShowLogo: false,
        isShowCallID: false,
        incomingCallNotificationChannelName: 'Incoming Call',
        missedCallNotificationChannelName: 'Missed Call',
        isShowFullLockedScreen: true,
      ),
      ios: const IOSParams(
        handleType: 'generic',
        supportsVideo: false,
        supportsDTMF: false,
        supportsHolding: false,
        supportsGrouping: false,
        supportsUngrouping: false,
      ),
    );

    await FlutterCallkitIncoming.showCallkitIncoming(params);
    AppLogger.info(
      'CallKit: Incoming UI shown callerId=${payload.callerId} callId=${payload.callId ?? 0}',
    );
  }

  Future<void> startOutboundCall({
    required String uuid,
    required String handle,
    String? nameCaller,
  }) async {
    final params = CallKitParams(
      id: uuid,
      nameCaller: nameCaller ?? handle,
      handle: handle,
      type: 1, // 1 for outgoing
      extra: <String, dynamic>{'userId': handle},
      ios: const IOSParams(handleType: 'generic'),
      android: const AndroidParams(
        isCustomNotification: true,
        isShowLogo: false,
        isShowCallID: false,
        ringtonePath: 'system_ringtone_default',
        backgroundColor: '#0955fa',
        backgroundUrl: 'assets/test.png',
        actionColor: '#4CAF50',
      ),
    );
    await FlutterCallkitIncoming.startCall(params);
  }

  Future<void> endCall(String callKitId) async {
    if (callKitId.trim().isEmpty) return;
    _armEndedSuppression();

    // İYİLEŞTİRME: CallKit arayüzünü kapatmadan önce native tarafa bildir.
    // Bu, kilit ekranındaki aramanın takılı kalmasını önler.
    await FlutterCallkitIncoming.endCall(callKitId);
  }

  Future<void> endAllCalls() async {
    _armEndedSuppression();
    await FlutterCallkitIncoming.endAllCalls();
  }

  Future<void> markConnected(String callKitId) async {
    if (callKitId.trim().isEmpty) return;
    await FlutterCallkitIncoming.setCallConnected(callKitId);
  }

  Future<String?> getVoipToken() async {
    final token = await FlutterCallkitIncoming.getDevicePushTokenVoIP();
    final normalized = token?.toString().trim();
    if (normalized == null || normalized.isEmpty) return null;
    return normalized;
  }

  String generateCallKitId() => _uuid.v4();

  Future<void> dispose() async {
    await _eventSubscription?.cancel();
    await _actionController.close();
    _initialized = false;
  }

  Future<void> _requestAndroidPermissions() async {
    try {
      await FlutterCallkitIncoming.requestNotificationPermission(
        <String, dynamic>{
          'title': 'Bildirim izni',
          'rationaleMessagePermission':
              'Gelen aramalarin gorunmesi icin bildirim izni gerekli.',
        },
      );
    } catch (_) {
      // no-op on iOS or unsupported platforms
    }

    try {
      await FlutterCallkitIncoming.requestFullIntentPermission();
    } catch (_) {
      // no-op on unsupported platforms
    }
  }

  void _armEndedSuppression() {
    _suppressEndedEventsUntilUtc = DateTime.now().toUtc().add(
      _endedSuppressionWindow,
    );
  }

  bool _isEndedSuppressed() {
    final until = _suppressEndedEventsUntilUtc;
    if (until == null) return false;
    return DateTime.now().toUtc().isBefore(until);
  }

  CallKitActionType _mapEventType(Event event) {
    switch (event) {
      case Event.actionCallIncoming:
        return CallKitActionType.incoming;
      case Event.actionCallAccept:
        return CallKitActionType.accepted;
      case Event.actionCallDecline:
        return CallKitActionType.declined;
      case Event.actionCallEnded:
        return CallKitActionType.ended;
      case Event.actionCallTimeout:
        return CallKitActionType.timeout;
      case Event.actionCallConnected:
        return CallKitActionType.connected;
      case Event.actionCallCallback:
        return CallKitActionType.callback;
      case Event.actionDidUpdateDevicePushTokenVoip:
        return CallKitActionType.devicePushTokenUpdated;
      case Event.actionCallStart:
      case Event.actionCallToggleHold:
      case Event.actionCallToggleMute:
      case Event.actionCallToggleDmtf:
      case Event.actionCallToggleGroup:
      case Event.actionCallToggleAudioSession:
      case Event.actionCallCustom:
        return CallKitActionType.unknown;
    }
  }
}
