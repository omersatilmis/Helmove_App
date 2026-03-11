import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../app/app_router.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/callkit_incoming_service.dart';
import '../../../../core/services/signalr_service.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../features/call/presentation/bloc/call_bloc.dart';
import '../../../../features/call/presentation/bloc/call_event.dart';
import '../../../../features/messages/presentation/pages/call_page.dart';
import '../../../../core/services/models/signalr_payloads.dart';

class CallListenerWrapper extends StatefulWidget {
  final Widget child;

  const CallListenerWrapper({super.key, required this.child});

  @override
  State<CallListenerWrapper> createState() => _CallListenerWrapperState();
}

class _CallListenerWrapperState extends State<CallListenerWrapper> {
  StreamSubscription<CallRequestPayload>? _incomingCallSub;
  StreamSubscription<CallKitAction>? _callKitActionSub;
  bool _isOpeningIncomingCall = false;
  int? _lastOpenedCallerId;
  DateTime? _lastOpenedAt;

  @override
  void initState() {
    super.initState();
    _listenToIncomingCalls();
    _listenToCallKitActions();
  }

  void _listenToIncomingCalls() {
    final signalR = sl<SignalRService>();
    if (!signalR.isConnected) {
      signalR.init();
    }

    _incomingCallSub = signalR.incomingCallStream.listen((payload) {
      if (!mounted) return;

      final callerId = _toInt(payload.callerId);
      if (callerId == null || callerId <= 0) {
        AppLogger.warning(
          'CallListenerWrapper: Invalid callerId in incoming payload: $payload',
        );
        return;
      }

      // [REFACTOR] CallKit logic updated: CallBloc now handles showing the CallKit UI.
      // This listener only opens the app UI *if the user is already looking at the phone*.
      // If the phone is locked, CallKit UI (shown by CallBloc) takes over native flow.
      _openIncomingCallPage(
        callerId: callerId,
        callId: _toInt(payload.callId),
        callerDisplayName: payload.callerDisplayName,
        autoAcceptIncoming: false, // User will interact with full screen UI
      );
    });
  }

  void _listenToCallKitActions() {
    final callKitService = sl<CallKitIncomingService>();
    unawaited(callKitService.initialize());

    _callKitActionSub = callKitService.actionStream.listen((action) async {
      if (!mounted) return;

      final payload = action.payload;
      switch (action.type) {
        case CallKitActionType.accepted:
          if (payload == null) return;
          await callKitService.endAllCalls();
          _openIncomingCallPage(
            callerId: payload.callerId,
            callId: payload.callId,
            callerDisplayName: payload.callerDisplayName,
            autoAcceptIncoming: true,
          );
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
          sl<CallBloc>().add(const CallHangUp());
          await callKitService.endAllCalls();
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

  void _openIncomingCallPage({
    required int callerId,
    required bool autoAcceptIncoming,
    int? callId,
    String? callerDisplayName,
  }) {
    if (_isOpeningIncomingCall) return;

    if (_lastOpenedCallerId == callerId &&
        _lastOpenedAt != null &&
        DateTime.now().difference(_lastOpenedAt!) <
            const Duration(seconds: 4)) {
      return;
    }

    final navigator = rootNavigatorKey.currentState;
    if (navigator == null) {
      AppLogger.warning(
        'CallListenerWrapper: rootNavigator is null, incoming call not opened.',
      );
      return;
    }

    final route = MaterialPageRoute(
      builder: (_) => CallPage(
        targetUserId: callerId,
        targetDisplayName: callerDisplayName,
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
  }

  int? _toInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return int.tryParse(value?.toString() ?? '');
  }

  @override
  void dispose() {
    _incomingCallSub?.cancel();
    _callKitActionSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
