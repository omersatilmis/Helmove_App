import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:moto_comm_app_1/core/theme/text_styles.dart';
import 'package:moto_comm_app_1/features/group_ride/presentation/bloc/group_ride_bloc.dart';
import 'package:moto_comm_app_1/features/group_ride/presentation/bloc/group_ride_event.dart';
import 'package:moto_comm_app_1/features/voice_session/domain/entities/voice_session_entity.dart';
import 'package:moto_comm_app_1/features/voice_session/presentation/bloc/voice_session_bloc.dart';
import 'package:moto_comm_app_1/features/voice_session/presentation/bloc/voice_session_event.dart';

class GroupPageActions {
  const GroupPageActions._();

  static void kickUser({
    required BuildContext context,
    required int sessionId,
    required int targetUserId,
    required String userName,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Kullanıcıyı At'),
        content: Text('$userName adlı kullanıcıyı atmak istiyor musunuz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<VoiceSessionBloc>().add(
                    KickUserEvent(sessionId, targetUserId),
                  );
            },
            child: const Text('At', style: TextStyle(color: Colors.red)),
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
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Kullanıcıyı Sustur'),
        content: Text('$userName adlı kullanıcıyı susturmak istiyor musunuz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<VoiceSessionBloc>().add(
                    MuteUserEvent(sessionId, targetUserId),
                  );
            },
            child: const Text('Sustur'),
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
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Host Yetkisini Devret'),
        content: Text(
          'Host yetkisini $userName adlı kullanıcıya devretmek istiyor musunuz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<VoiceSessionBloc>().add(
                    TransferHostEvent(sessionId, targetUserId),
                  );
            },
            child: const Text('Devret'),
          ),
        ],
      ),
    );
  }

  static void showLeaveDialog({
    required BuildContext context,
    required VoiceSessionEntity? sessionDetails,
    required int rideId,
  }) {
    final currentUserId = context.read<VoiceSessionBloc>().state.currentUserId;

    final isHost = sessionDetails?.hostUserId == currentUserId;

    final participants = sessionDetails?.participants ?? [];
    final activeCount = participants
        .where((p) => p.status == 'Joined' || p.status == 'Accepted')
        .length;
    final hasOthers = activeCount > 1;

    if (isHost && hasOthers) {
      _showSmartLeaveDialog(context, rideId);
    } else {
      _showStandardLeaveDialog(context, rideId);
    }
  }

  static void _showStandardLeaveDialog(BuildContext context, int rideId) {
    final colorScheme = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colorScheme.surfaceContainerHigh,
        title: Text('Odadan Ayrıl', style: AppTextStyles.h3),
        content: Text(
          'Bu sürüş grubundan ayrılmak istediğinize emin misiniz?',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('İptal', style: TextStyle(color: colorScheme.primary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _performLeave(context, rideId);
            },
            child: Text(
              'Ayrıl',
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

  static void _showSmartLeaveDialog(BuildContext context, int rideId) {
    final colorScheme = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colorScheme.surfaceContainerHigh,
        title: Text('Gruptan Ayrılıyor musunuz?', style: AppTextStyles.h3),
        content: Text('Ne yapmak istersiniz?', style: AppTextStyles.bodyMedium),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'İptal',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _performLeave(context, rideId);
            },
            child: Text(
              'Ayrıl & Devret',
              style: TextStyle(
                color: Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _performTerminate(context, rideId);
            },
            child: Text(
              'Grubu Sonlandır',
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

  static void _performLeave(BuildContext context, int rideId) {
    if (rideId > 0) {
      context.read<GroupRideBloc>().add(LeaveGroupRideEvent(rideId));
    } else {
      Navigator.of(context).pop();
    }
  }

  static void _performTerminate(BuildContext context, int rideId) {
    if (rideId > 0) {
      context.read<GroupRideBloc>().add(DeleteGroupRideEvent(rideId));
    } else {
      Navigator.of(context).pop();
    }
  }
}
