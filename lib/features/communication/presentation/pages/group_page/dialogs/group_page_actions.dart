import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:helmove/core/theme/text_styles.dart';
import 'package:helmove/features/group_ride/presentation/bloc/group_ride_bloc.dart';
import 'package:helmove/features/group_ride/presentation/bloc/group_ride_event.dart';
import 'package:helmove/features/voice_session/domain/entities/voice_session_entity.dart';
import 'package:helmove/features/voice_session/presentation/bloc/voice_session_bloc.dart';
import 'package:helmove/features/voice_session/presentation/bloc/voice_session_event.dart';
import 'package:helmove/features/attendance_management/domain/entities/group_role.dart';
import 'package:helmove/l10n/app_localizations.dart';

class GroupPageActions {
  const GroupPageActions._();

  static void kickUser({
    required BuildContext context,
    required int sessionId,
    required int targetUserId,
    required String userName,
  }) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.kickUserTitle),
        content: Text(l10n.kickUserConfirmation(userName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<VoiceSessionBloc>().add(
                KickUserEvent(sessionId, targetUserId),
              );
            },
            child: Text(l10n.kick, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  static void muteUser({
    required BuildContext context,
    required int sessionId,
    required int targetUserId,
    required String userName,
  }) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.muteUserTitle),
        content: Text(l10n.muteUserConfirmation(userName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<VoiceSessionBloc>().add(
                MuteUserEvent(sessionId, targetUserId),
              );
            },
            child: Text(l10n.mute),
          ),
        ],
      ),
    );
  }

  static void transferHost({
    required BuildContext context,
    required int sessionId,
    required int targetUserId,
    required String userName,
  }) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.transferLeadership),
        content: Text(l10n.transferLeadershipConfirmation(userName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<VoiceSessionBloc>().add(
                TransferHostEvent(sessionId, targetUserId),
              );
            },
            child: Text(l10n.transfer),
          ),
        ],
      ),
    );
  }

  static void promoteUser({
    required BuildContext context,
    required int sessionId,
    required int targetUserId,
    required String userName,
  }) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.promoteToCaptainTitle),
        content: Text(l10n.promoteToCaptainConfirmation(userName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<VoiceSessionBloc>().add(
                PromoteParticipantEvent(sessionId, targetUserId),
              );
            },
            child: Text(l10n.makeCaptain),
          ),
        ],
      ),
    );
  }

  static void demoteUser({
    required BuildContext context,
    required int sessionId,
    required int targetUserId,
    required String userName,
  }) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.demoteToRiderTitle),
        content: Text(l10n.demoteToRiderConfirmation(userName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<VoiceSessionBloc>().add(
                DemoteParticipantEvent(sessionId, targetUserId),
              );
            },
            child: Text(l10n.demote),
          ),
        ],
      ),
    );
  }

  static void showLeaveDialog({
    required BuildContext context,
    required VoiceSessionEntity? sessionDetails,
    required int rideId,
    required int? sessionId,
  }) {
    final currentUserId = context.read<VoiceSessionBloc>().state.currentUserId;

    final isHost =
        sessionDetails?.adminId == currentUserId ||
        (currentUserId != null &&
            sessionDetails?.participants.any(
                  (p) =>
                      p.userId == currentUserId &&
                      (p.role == GroupRole.admin ||
                          p.role == GroupRole.captain),
                ) ==
                true); // Admin/Captain kontrolü

    final participants = sessionDetails?.participants ?? [];
    final activeCount = participants
        .where((p) => p.status == 'Joined' || p.status == 'Accepted')
        .length;

    // [New Requirement] If sole participant (or 0), treat Leave as Terminate
    if (activeCount <= 1) {
      _showLastPersonLeaveDialog(context, rideId, sessionId);
      return;
    }

    if (isHost) {
      _showSmartLeaveDialog(context, rideId, sessionId);
    } else {
      _showStandardLeaveDialog(context, rideId, sessionId);
    }
  }

  static void _showLastPersonLeaveDialog(
    BuildContext context,
    int rideId,
    int? sessionId,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colorScheme.surfaceContainerHigh,
        title: Text(l10n.terminateGroupTitle, style: AppTextStyles.h3),
        content: Text(
          l10n.lastPersonLeaveWarning,
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel, style: TextStyle(color: colorScheme.primary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _performTerminate(context, rideId, sessionId);
            },
            child: Text(
              l10n.terminateAndExit,
              style: TextStyle(
                color: colorScheme.error,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static void _showStandardLeaveDialog(
    BuildContext context,
    int rideId,
    int? sessionId,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colorScheme.surfaceContainerHigh,
        title: Text(l10n.leaveRoomTitle, style: AppTextStyles.h3),
        content: Text(
          l10n.leaveGroupConfirmation,
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel, style: TextStyle(color: colorScheme.primary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _performLeave(context, rideId, sessionId);
            },
            child: Text(
              l10n.leave,
              style: TextStyle(
                color: colorScheme.error,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static void _showSmartLeaveDialog(
    BuildContext context,
    int rideId,
    int? sessionId,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colorScheme.surfaceContainerHigh,
        title: Text(l10n.leavingGroupQuestion, style: AppTextStyles.h3),
        content: Text(l10n.whatToDo, style: AppTextStyles.bodyMedium),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              l10n.cancel,
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _performLeave(context, rideId, sessionId);
            },
            child: Text(
              l10n.leaveAndTransfer,
              style: TextStyle(
                color: Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _performTerminate(context, rideId, sessionId);
            },
            child: Text(
              l10n.terminateGroupTitle,
              style: TextStyle(
                color: colorScheme.error,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static int? _resolveValidSessionId(BuildContext context, int? sessionId) {
    var resolvedSessionId = sessionId;

    if (resolvedSessionId == null || resolvedSessionId <= 0) {
      final state = context.read<VoiceSessionBloc>().state;
      if (state.session != null && state.session!.id > 0) {
        resolvedSessionId = state.session!.id;
      } else if (state.sessionId != null && state.sessionId! > 0) {
        resolvedSessionId = state.sessionId;
      }
    }

    if (resolvedSessionId != null && resolvedSessionId > 0) {
      return resolvedSessionId;
    }

    return null;
  }

  static void _performLeave(BuildContext context, int rideId, int? sessionId) {
    final validSessionId = _resolveValidSessionId(context, sessionId);

    // BLoC Senkronizasyonu: Ayrılma işlemi gerçekleşirken yerel veriyi temizle
    context.read<GroupRideBloc>().add(const ClearGroupDataEvent());

    if (rideId > 0) {
      context.read<GroupRideBloc>().add(
            LeaveGroupRideEvent(rideId, sessionId: validSessionId),
          );
    }
    if (validSessionId != null && validSessionId > 0) {
      context.read<VoiceSessionBloc>().add(
            LeaveVoiceSessionEvent(validSessionId),
          );
    }
  }

  static void _performTerminate(
    BuildContext context,
    int rideId,
    int? sessionId,
  ) {
    final validSessionId = _resolveValidSessionId(context, sessionId);

    // BLoC Senkronizasyonu: Sonlandırma işlemi gerçekleşirken yerel veriyi temizle
    context.read<GroupRideBloc>().add(const ClearGroupDataEvent());

    if (rideId > 0) {
      context.read<GroupRideBloc>().add(
            DeleteGroupRideEvent(rideId, sessionId: validSessionId),
          );
    }
    if (validSessionId != null && validSessionId > 0) {
      context.read<VoiceSessionBloc>().add(
            EndVoiceSessionEvent(validSessionId),
          );
    }
  }
}
