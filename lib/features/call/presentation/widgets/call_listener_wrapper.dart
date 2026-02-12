import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../app/app_router.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/signalr_service.dart';
import '../../../../features/messages/presentation/pages/call_page.dart';

/// Listens incoming 1v1 call events globally and opens incoming [CallPage].
class CallListenerWrapper extends StatefulWidget {
  final Widget child;

  const CallListenerWrapper({super.key, required this.child});

  @override
  State<CallListenerWrapper> createState() => _CallListenerWrapperState();
}

class _CallListenerWrapperState extends State<CallListenerWrapper> {
  StreamSubscription<Map<String, dynamic>>? _incomingCallSub;
  bool _isOpeningIncomingCall = false;

  @override
  void initState() {
    super.initState();
    _listenToIncomingCalls();
  }

  void _listenToIncomingCalls() {
    final signalR = sl<SignalRService>();
    if (!signalR.isConnected) {
      signalR.init();
    }

    _incomingCallSub = signalR.incomingCallStream.listen((data) {
      if (!mounted) return;

      final callerId = _toInt(data['callerId']) ?? _toInt(data['CallerId']);
      if (callerId == null || callerId <= 0) {
        debugPrint(
          'CallListenerWrapper: Invalid callerId in incoming call payload: $data',
        );
        return;
      }

      final callId = _toInt(data['callId']) ?? _toInt(data['CallId']);
      final callerDisplayName =
          data['callerDisplayName']?.toString() ??
          data['CallerDisplayName']?.toString() ??
          data['displayName']?.toString();

      if (_isOpeningIncomingCall) {
        debugPrint('CallListenerWrapper: Incoming call page already opening.');
        return;
      }

      final route = MaterialPageRoute(
        builder: (_) => CallPage(
          targetUserId: callerId,
          targetDisplayName: callerDisplayName,
          isOutgoing: false,
          callId: callId,
        ),
      );

      final navigator = rootNavigatorKey.currentState;
      if (navigator == null) {
        debugPrint(
          'CallListenerWrapper: rootNavigator is null, incoming call page not opened.',
        );
        return;
      }

      _isOpeningIncomingCall = true;
      navigator.push(route).whenComplete(() {
        _isOpeningIncomingCall = false;
      });
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
