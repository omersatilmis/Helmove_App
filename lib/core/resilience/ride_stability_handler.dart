import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:helmove/core/resilience/stability_handler.dart';
import 'package:helmove/features/group_ride/presentation/bloc/group_ride_bloc.dart';
import 'package:helmove/features/group_ride/presentation/bloc/group_ride_event.dart';
import 'package:helmove/features/group_ride/presentation/bloc/group_ride_state.dart';
import 'package:helmove/features/voice_session/presentation/bloc/voice_session_bloc.dart';
import 'package:helmove/features/voice_session/presentation/bloc/voice_session_event.dart';
import 'package:helmove/features/voice_session/presentation/bloc/voice_session_state.dart';

class RideStabilityHandler
    extends StabilityHandler<GroupRideBloc, GroupRideState> {
  final VoiceSessionBloc voiceBloc;

  RideStabilityHandler(super.bloc, this.voiceBloc);

  @override
  void handleState(BuildContext context, GroupRideState state) {
    // 1. Kicked
    if (state is GroupRideKicked) {
      _leaveVoiceIfNeeded();
      _handleExit(context, state.message, isError: true);
    }
    // 2. Deleted
    else if (state is GroupRideDeleted) {
      _leaveVoiceIfNeeded();
      _handleExit(
        context,
        "Grup kurucu tarafında sonlandırıldı.",
        isError: true,
      );
    }
    // 3. Admin Changed (Notification Only)
    else if (state is GroupRideAdminChanged) {
      showNotification(context, state.message);
    }
    // 4. Critical Error (404/403)
    else if (state is GroupRideFailure) {
      if (state.message.contains("404") ||
          state.message.contains("Bulunamadı")) {
        _handleExit(context, "Grup artık mevcut değil.", isError: true);
      } else if (state.message.contains("403") ||
          state.message.contains("Yetki")) {
        _handleExit(context, "Erişim reddedildi.", isError: true);
      }
    }
    // 5. Terminated
    else if (state is GroupRideTerminated) {
      _leaveVoiceIfNeeded();
      _handleExit(
        context,
        "Grup turu organizatör tarafından sonlandırıldı.",
        isError: true,
      );
    }
    // 6. Left
    else if (state is GroupRideLeft) {
      _leaveVoiceIfNeeded();
      _handleExit(context, "Gruptan ayrıldınız.");
    }
  }

  void _handleExit(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    // 1. Notify User
    showNotification(context, message, isError: isError);

    // 2. Clear Data (Ghost Data Prevention)
    bloc.add(const ClearGroupDataEvent());

    // 3. Smart Redirect
    // Only redirect if we are inside a group-related page
    final String location = GoRouterState.of(context).uri.toString();
    if (location.contains('/communication/group-page') ||
        location.contains('/communication/active-ride') ||
        location.contains('/communication/invite')) {
      context.go('/communication');
    }
  }

  void _leaveVoiceIfNeeded() {
    final voiceState = voiceBloc.state;
    final sessionId = voiceState.session?.id;
    if (sessionId != null &&
        sessionId > 0 &&
        voiceState.status != VoiceSessionStatus.left) {
      voiceBloc.add(LeaveVoiceSessionEvent(sessionId));
    }
  }
}
