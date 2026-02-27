import 'package:flutter/material.dart';

import 'package:moto_comm_app_1/core/theme/text_styles.dart';
import 'package:moto_comm_app_1/core/widgets/app_frosted_button.dart';
import 'package:moto_comm_app_1/features/communication/presentation/widgets/rider_card.dart';
import 'package:moto_comm_app_1/features/group_ride/presentation/models/group_ride_args.dart';
import 'package:moto_comm_app_1/features/intercom/domain/intercom_models.dart';
import 'package:moto_comm_app_1/features/voice_session/domain/entities/voice_session_entity.dart';
import 'package:moto_comm_app_1/features/attendance_management/domain/entities/group_role.dart';

class GroupParticipantsSection extends StatelessWidget {
  final GroupRideArgs data;
  final VoiceSessionEntity? sessionDetails;
  final bool isLoadingSession;
  final int? currentUserId;
  final bool showSettingsButton;
  final Set<String> activeSpeakers;
  final Map<int, IntercomConnectionQuality> participantQualities;
  final bool isCurrentUserMicOn;
  final VoidCallback onToggleMic;
  final VoidCallback onRefresh;
  final VoidCallback onInvite;
  final VoidCallback onSettings;
  final void Function(int targetUserId, String userName) onKickUser;
  final void Function(int targetUserId, String userName) onMuteUser;
  final void Function(int targetUserId, String userName) onTransferHost;
  final void Function(int targetUserId, String userName) onPromote;
  final void Function(int targetUserId, String userName) onDemote;

  const GroupParticipantsSection({
    super.key,
    required this.data,
    required this.sessionDetails,
    required this.isLoadingSession,
    required this.currentUserId,
    required this.showSettingsButton,
    required this.activeSpeakers,
    this.participantQualities = const {},
    required this.isCurrentUserMicOn,
    required this.onToggleMic,
    required this.onRefresh,
    required this.onInvite,
    required this.onSettings,
    required this.onKickUser,
    required this.onMuteUser,
    required this.onTransferHost,
    required this.onPromote,
    required this.onDemote,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "CONNECTED RIDERS",
              style: AppTextStyles.bodySmall.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
            Row(
              children: [
                AppFrostedButton(
                  icon: Icons.refresh,
                  size: 40,
                  iconSize: 20,
                  onTap: onRefresh,
                ),
                const SizedBox(width: 12),
                AppFrostedButton(
                  icon: Icons.person_add,
                  size: 40,
                  iconSize: 20,
                  onTap: onInvite,
                ),
                if (showSettingsButton) ...[
                  const SizedBox(width: 12),
                  AppFrostedButton(
                    icon: Icons.settings,
                    size: 40,
                    iconSize: 20,
                    onTap: onSettings,
                  ),
                ],
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (isLoadingSession)
          const Padding(
            padding: EdgeInsets.all(20.0),
            child: Center(child: CircularProgressIndicator()),
          )
        else
          _buildParticipantList(context),
      ],
    );
  }

  Widget _buildParticipantList(BuildContext context) {
    final participants =
        sessionDetails?.participants
            .where(
              (p) =>
                  p.status == 'Joined' ||
                  p.status == 'Accepted' ||
                  p.status == 'Disconnected',
            )
            .toList() ??
        [];

    if (participants.isEmpty) return _buildEmptyState(context);

    final hostId = sessionDetails?.hostUserId;

    // Current user'ın role'ünü participant listesinden al (backend'den gelir)
    GroupRole viewerRole = GroupRole.rider;
    if (currentUserId != null) {
      final currentParticipant = participants
          .where((p) => p.userId == currentUserId)
          .firstOrNull;
      if (currentParticipant != null) {
        viewerRole = currentParticipant.role;
      } else if (hostId == currentUserId) {
        // Fallback: host her zaman Admin'dir
        viewerRole = GroupRole.admin;
      }
    }

    return Column(
      children: participants.map((p) {
        final isConnected = p.status == 'Joined' || p.status == 'Accepted';
        final isMe = p.userId == currentUserId;

        final role = p.role;
        final quality =
            participantQualities[p.userId] ?? IntercomConnectionQuality.unknown;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: RiderCard(
            firstName: p.firstName ?? '',
            lastName: p.lastName ?? '',
            profileImageUrl:
                p.profileImage ?? 'https://i.pravatar.cc/150?u=${p.userId}',
            phoneBatteryLevel: p.phoneBatteryLevel,
            intercomBatteryLevel: p.intercomBatteryLevel,
            signalStrength: p.signalStrength,
            connectionQuality: quality,
            isMicOn: isMe ? isCurrentUserMicOn : false,
            isSpeaking: activeSpeakers.contains(p.userId.toString()),
            isConnected: isConnected,
            isMe: isMe,
            isRemoteMuted: p.isRemoteMuted,
            role: role,
            viewerRole: viewerRole,
            onMicPressed: isMe ? onToggleMic : null,
            onKickUser:
                ((viewerRole == GroupRole.admin ||
                        viewerRole == GroupRole.captain) &&
                    !isMe)
                ? () => onKickUser(p.userId, p.firstName ?? 'Kullanıcı')
                : null,
            onMuteUser:
                ((viewerRole == GroupRole.admin ||
                        viewerRole == GroupRole.captain) &&
                    !isMe)
                ? () => onMuteUser(p.userId, p.firstName ?? 'Kullanıcı')
                : null,
            onTransferHost: (viewerRole == GroupRole.admin && !isMe)
                ? () => onTransferHost(p.userId, p.firstName ?? 'Kullanıcı')
                : null,
            onPromote:
                (viewerRole == GroupRole.admin &&
                    p.role == GroupRole.rider &&
                    !isMe)
                ? () => onPromote(p.userId, p.firstName ?? 'Kullanıcı')
                : null,
            onDemote:
                (viewerRole == GroupRole.admin &&
                    p.role == GroupRole.captain &&
                    !isMe)
                ? () => onDemote(p.userId, p.firstName ?? 'Kullanıcı')
                : null,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Icon(
              Icons.people_outline,
              size: 48,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 8),
            Text(
              "Henüz kimse katılmadı.",
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
