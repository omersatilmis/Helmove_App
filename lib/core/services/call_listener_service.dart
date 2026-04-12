import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import '../navigation/navigator_keys.dart';
import '../di/injection_container.dart';
import '../utils/app_logger.dart';
import 'callkit_incoming_service.dart';
import 'signalr_service.dart';
import 'models/signalr_payloads.dart';
import '../../features/call/presentation/bloc/call_bloc.dart';
import '../../features/call/presentation/bloc/call_event.dart';
import '../../features/call/presentation/bloc/call_state.dart';
import '../../features/messages/presentation/pages/call_page.dart';

/// Widget tree dışında çalışan çağrı dinleyici servisi.
///
/// Eskiden [CallListenerWrapper] adlı bir StatefulWidget ile
/// MaterialApp.builder içinde sarmalanıyordu. Bu yaklaşım widget
/// ağacına gereksiz ~8 frame ekleyerek stack overflow'a yol açıyordu.
///
/// Bu servis aynı işlevselliği widget ağacı dışında sağlar.
class CallListenerService {
  StreamSubscription<CallRequestPayload>? _incomingCallSub;
  StreamSubscription<CallKitAction>? _callKitActionSub;
  bool _isOpeningIncomingCall = false;
  int? _lastOpenedCallerId;
  DateTime? _lastOpenedAt;
  bool _started = false;

  /// Servisi başlat. Birden fazla çağrıya karşı korumalıdır.
  void start() {
    if (_started) return;
    _started = true;
    _listenToIncomingCalls();
    _listenToCallKitActions();
  }

  void _listenToIncomingCalls() {
    final signalR = sl<SignalRService>();
    // SignalR init artık tek merkezden (RealTimeService + AppSession token stream) yapılıyor.
    // Burada sadece stream'e abone oluyoruz.

    _incomingCallSub = signalR.incomingCallStream.listen((payload) {
      final callerId = _toInt(payload.callerId);
      if (callerId == null || callerId <= 0) {
        AppLogger.warning(
          'CallListenerService: Invalid callerId in incoming payload: $payload',
        );
        return;
      }

      final lifecycle = WidgetsBinding.instance.lifecycleState;
      final isForeground = lifecycle == AppLifecycleState.resumed;

      if (!isForeground) {
        AppLogger.info(
          'CallListenerService: Incoming SignalR event received for caller=$callerId while app is background. '
          'Waiting for CallKit flow.',
        );
        return;
      }

      _openIncomingCallPage(
        callerId: callerId,
        callId: _toInt(payload.callId),
        callerDisplayName: payload.callerDisplayName,
        callerProfileImageUrl: payload.callerProfileImageUrl,
        autoAcceptIncoming: false,
      );
    });
  }

  void _listenToCallKitActions() {
    final callKitService = sl<CallKitIncomingService>();
    unawaited(callKitService.initialize());

    _callKitActionSub = callKitService.actionStream.listen((action) async {
      final payload = action.payload;
      switch (action.type) {
        case CallKitActionType.accepted:
          if (payload == null) return;
          await callKitService.endAllCalls();
          final opened = _openIncomingCallPage(
            callerId: payload.callerId,
            callId: payload.callId,
            callerDisplayName: payload.callerDisplayName,
            callerProfileImageUrl: payload.callerProfileImageUrl,
            autoAcceptIncoming: true,
          );
          if (!opened) {
            _dispatchIncomingAcceptToBloc(
              callerId: payload.callerId,
              callId: payload.callId,
              callerDisplayName: payload.callerDisplayName,
              callerProfileImageUrl: payload.callerProfileImageUrl,
            );
          }
          break;
        case CallKitActionType.declined:
          if (payload == null) return;
          sl<CallBloc>().add(
            CallIncomingReceived(
              callerId: payload.callerId,
              callerDisplayName: payload.callerDisplayName,
              callId: payload.callId,
            ),
          );
          sl<CallBloc>().add(const CallRejected());
          await callKitService.endAllCalls();
          break;
        case CallKitActionType.timeout:
        case CallKitActionType.ended:
          final callBloc = sl<CallBloc>();
          final callState = callBloc.state;

          // Simulator/iOS CallKit bazen connecting/active sırasında false ended
          // callback üretebiliyor. Bu durumda görüşmeyi otomatik kapatma.
          if (callState is CallConnecting || callState is CallActive) {
            AppLogger.warning(
              'CallListenerService: Ignoring CallKit ${action.type.name} while call is ${callState.runtimeType}.',
            );
            break;
          }

          // iOS outgoing CallKit bazen anlik timeout/ended callback uretebiliyor.
          // Bu durumda aramayi otomatik kapatmak false-positive'e neden olur.
          if (callState is CallOutgoing) {
            AppLogger.warning(
              'CallListenerService: Ignoring CallKit ${action.type.name} while outgoing call is active.',
            );
            break;
          }

            final hasActiveCall = callState is CallIncoming;
          if (hasActiveCall) {
            callBloc.add(const CallHangUp());
            await callKitService.endAllCalls();
          }
          break;
        case CallKitActionType.devicePushTokenUpdated:
        case CallKitActionType.incoming:
        case CallKitActionType.connected:
        case CallKitActionType.callback:
        case CallKitActionType.unknown:
          break;
      }
    });
  }

  bool _openIncomingCallPage({
    required int callerId,
    required bool autoAcceptIncoming,
    int? callId,
    String? callerDisplayName,
    String? callerProfileImageUrl,
  }) {
    if (_isOpeningIncomingCall) return false;

    if (_lastOpenedCallerId == callerId &&
        _lastOpenedAt != null &&
        DateTime.now().difference(_lastOpenedAt!) <
            const Duration(seconds: 4)) {
      return false;
    }

    final navigator = rootNavigatorKey.currentState;
    if (navigator == null) {
      AppLogger.warning(
        'CallListenerService: rootNavigator is null, incoming call not opened.',
      );
      return false;
    }

    final route = MaterialPageRoute(
      builder: (_) => CallPage(
        targetUserId: callerId,
        targetDisplayName: callerDisplayName,
        targetProfileImageUrl: callerProfileImageUrl,
        isOutgoing: false,
        autoAcceptIncoming: autoAcceptIncoming,
        callId: callId,
      ),
    );

    _isOpeningIncomingCall = true;
    _lastOpenedCallerId = callerId;
    _lastOpenedAt = DateTime.now();
    navigator.push(route).whenComplete(() {
      _isOpeningIncomingCall = false;
    });
    return true;
  }

  void _dispatchIncomingAcceptToBloc({
    required int callerId,
    int? callId,
    String? callerDisplayName,
    String? callerProfileImageUrl,
  }) {
    final bloc = sl<CallBloc>();
    bloc.add(
      CallIncomingReceived(
        callerId: callerId,
        callerDisplayName: callerDisplayName,
        callerProfileImageUrl: callerProfileImageUrl,
        callId: callId,
      ),
    );
    bloc.add(const CallAccepted());
  }

  int? _toInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return int.tryParse(value?.toString() ?? '');
  }

  /// Servis kapatılırken çağrılır (genellikle app lifecycle event ile).
  void dispose() {
    _incomingCallSub?.cancel();
    _callKitActionSub?.cancel();
    _started = false;
  }
}
