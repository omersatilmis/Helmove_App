import 'package:flutter/material.dart';
// ignore: unused_import
import 'package:go_router/go_router.dart';
import 'package:helmove/core/resilience/stability_handler.dart';
import 'package:helmove/features/voice_session/presentation/bloc/voice_session_bloc.dart';
import 'package:helmove/features/voice_session/presentation/bloc/voice_session_event.dart';
import 'package:helmove/features/voice_session/presentation/bloc/voice_session_state.dart';

class VoiceStabilityHandler
    extends StabilityHandler<VoiceSessionBloc, VoiceSessionState> {
  VoiceStabilityHandler(super.bloc);

  String? _lastHandledError;

  @override
  void handleState(BuildContext context, VoiceSessionState state) {
    // Reset dedup if we are back to a healthy state
    if (state.status != VoiceSessionStatus.error) {
      _lastHandledError = null;
    }

    if (state.status == VoiceSessionStatus.ended) {
      _handleExit(context, "Sesli oturum sonlandırıldı.");
    } else if (state.status == VoiceSessionStatus.preJoinError) {
      _handleExit(
        context,
        state.message ?? "Oturuma katılılamadı.",
        isError: true,
      );
    } else if (state.status == VoiceSessionStatus.kicked) {
      _handleExit(context, "Sesli oturumdan atıldınız.", isError: true);
    } else if (state.status == VoiceSessionStatus.error) {
      final msg = state.message;

      // [NEW] Permission / UX Safety
      if (msg != null && msg.contains('Mikrofon izni gerekli')) {
        if (_lastHandledError != msg) {
          showNotification(context, msg, isError: true);
          _lastHandledError = msg;
          // Audio Prompt hook would go here
        }
        return; // Do NOT exit session
      }

      // Critical errors only
      if (msg != null && (msg.contains("404") || msg.contains("403"))) {
        _handleExit(context, msg, isError: true);
      }
    }
  }

  void _handleExit(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    showNotification(context, message, isError: isError);

    bloc.add(const ClearSessionDataEvent());

    // NOTE: Voice limits generally don't force page redirects usually, unless specifically requested.
    // For now, we rely on SnackBar.
  }
}
