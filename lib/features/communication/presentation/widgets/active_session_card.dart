import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../voice_session/domain/entities/voice_session_entity.dart';
import '../../../voice_session/presentation/bloc/voice_session_bloc.dart';
import '../../../voice_session/presentation/bloc/voice_session_event.dart';
import '../../../voice_session/presentation/bloc/voice_session_state.dart';
import '../../../attendance_management/domain/entities/group_role.dart';
import '../../../group_ride/presentation/models/group_ride_args.dart';
import 'active_group.dart';
import 'rider_card.dart';

class ActiveSessionCard extends StatelessWidget {
  const ActiveSessionCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final currentUserId = context.select<VoiceSessionBloc, int?>(
      (bloc) => bloc.state.currentUserId,
    );
    final isMicOn = context.select<VoiceSessionBloc, bool>(
      (bloc) => bloc.state.isMicOn,
    );
    // 1. Aktif oturum özeti (Liste verisinden gelir - Katılımcılar eksik olabilir)
    final activeSessionSummary =
        context.select<VoiceSessionBloc, VoiceSessionEntity?>(
      (bloc) => bloc.state.activeSession,
    );
    // 2. Detaylı oturum verisi (Detay endpoint'inden gelir - Katılımcılar tamdır)
    final detailedSession =
        context.select<VoiceSessionBloc, VoiceSessionEntity?>(
      (bloc) => bloc.state.session,
    );

    // İlk yükleme: mySessions henüz null ise ve status loading ise spinner göster
    final isInitialLoading = context.select<VoiceSessionBloc, bool>(
      (bloc) =>
          bloc.state.mySessions == null &&
          bloc.state.status == VoiceSessionStatus.loading,
    );

    if (isInitialLoading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: CircularProgressIndicator(color: colorScheme.primary),
        ),
      );
    }

    if (activeSessionSummary == null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLow.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: colorScheme.outline.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.groups_outlined,
                  size: 48,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 12),
                Text(
                  'Aktif odanız yok',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    'Yeni bir oda oluşturun veya davet bekleyin',
                    style: AppTextStyles.bodySmall.copyWith(
                      color:
                          colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // 3. AKILLI VERİ SEÇİMİ (Merge Logic)
    final displaySession =
        (detailedSession != null && detailedSession.id == activeSessionSummary.id)
            ? detailedSession
            : activeSessionSummary;

    // 4. Katılımcı listesini seçilen doğru oturum (displaySession) üzerinden al
    final participants = displaySession.participants.where((p) {
      return p.status == 'Joined' ||
          p.status == 'Accepted' ||
          p.status == 'Disconnected';
    }).toList();

    return ActiveGroupCard(
      groupName: displaySession.title,
      currentParticipants: participants.length,
      maxParticipants: displaySession.maxParticipants,
      destination: displaySession.destination,
      ridingStyle: displaySession.ridingStyle,
      difficulty: displaySession.difficulty,
      isActive: displaySession.isActive,
      onOpenPressed: () async {
        final args = GroupRideArgs(
          rideId: displaySession.rideId ?? 0,
          sessionId: displaySession.id,
          groupName: displaySession.title,
          maxParticipants: displaySession.maxParticipants,
          currentParticipants: participants.length,
        );
        final result = await context.push<bool>(
          '/communication/group-page',
          extra: args,
        );

        if (context.mounted) {
          if (result == true) {
            await Future.delayed(const Duration(milliseconds: 1500));
          }
          if (context.mounted) {
            context.read<VoiceSessionBloc>().add(
                  const GetMyVoiceSessionsEvent(force: true),
                );
          }
        }
      },
      riderCards: participants.map((p) {
        final isConnected = p.status == 'Joined' || p.status == 'Accepted';
        final isMe = p.userId == currentUserId;

        GroupRole viewerRole = GroupRole.rider;
        if (currentUserId != null && displaySession.hostUserId == currentUserId) {
          viewerRole = GroupRole.captain;
        }

        GroupRole targetRole = GroupRole.rider;
        if (p.userId == displaySession.hostUserId) {
          targetRole = GroupRole.captain;
        }

        return RiderCard(
          key: ValueKey(p.userId),
          firstName: p.firstName ?? '',
          lastName: p.lastName ?? '',
          profileImageUrl:
              p.profileImage ?? 'https://i.pravatar.cc/150?u=${p.userId}',
          phoneBatteryLevel: p.phoneBatteryLevel,
          intercomBatteryLevel: p.intercomBatteryLevel,
          signalStrength: p.signalStrength,
          isMicOn: isMe ? isMicOn : false,
          isSpeaking: isConnected,
          isConnected: isConnected,
          isMe: isMe,
          role: targetRole,
          viewerRole: viewerRole,
          onMicPressed: isMe
              ? () => context.read<VoiceSessionBloc>().add(
                    const ToggleMicrophoneEvent(),
                  )
              : null,
          onKickUser: null,
          onMuteUser: null,
          onTransferHost: null,
        );
      }).toList(),
    );
  }
}