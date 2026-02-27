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
        title: const Text('Kullaniciyi At'),
        content: Text('$userName adli kullaniciyi atmak istiyor musunuz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Iptal'),
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
        title: const Text('Kullaniciyi Sustur'),
        content: Text('$userName adli kullaniciyi susturmak istiyor musunuz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Iptal'),
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
        title: const Text('Captain Yetkisini Devret'),
        content: Text(
          'Captain yetkisini $userName adli kullaniciya devretmek istiyor musunuz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Iptal'),
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

  static void promoteUser({
    required BuildContext context,
    required int sessionId,
    required int targetUserId,
    required String userName,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Captain Yap'),
        content: Text(
          '$userName kullanıcısına Captain yetkisi vermek istiyor musunuz?',
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
                PromoteParticipantEvent(sessionId, targetUserId),
              );
            },
            child: const Text('Captain Yap'),
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
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rider Yap'),
        content: Text(
          '$userName kullanıcısının Captain yetkisini kaldırmak istiyor musunuz?',
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
                DemoteParticipantEvent(sessionId, targetUserId),
              );
            },
            child: const Text('Rider Yap', style: TextStyle(color: Colors.orange)),
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

    final isHost = sessionDetails?.hostUserId == currentUserId; // Captain kontrolü

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
    final colorScheme = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colorScheme.surfaceContainerHigh,
        title: Text('Grubu Sonlandır', style: AppTextStyles.h3),
        content: Text(
          'Grupta kalan son kişisiniz. Ayrıldığınızda grup ve ses oturumu tamamen sonlandırılacak.',
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
              _performTerminate(context, rideId, sessionId);
            },
            child: Text(
              'Sonlandır ve Çık',
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
              _performLeave(context, rideId, sessionId);
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

  static void _showSmartLeaveDialog(
    BuildContext context,
    int rideId,
    int? sessionId,
  ) {
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
              _performLeave(context, rideId, sessionId);
            },
            child: const Text(
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
              _performTerminate(context, rideId, sessionId);
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

    if (rideId > 0) {
      context.read<GroupRideBloc>().add(
        LeaveGroupRideEvent(rideId, sessionId: validSessionId),
      );
    }
  }

  static void _performTerminate(
    BuildContext context,
    int rideId,
    int? sessionId,
  ) {
    final validSessionId = _resolveValidSessionId(context, sessionId);

    if (rideId > 0) {
      context.read<GroupRideBloc>().add(
        DeleteGroupRideEvent(rideId, sessionId: validSessionId),
      );
    }
  }
}
