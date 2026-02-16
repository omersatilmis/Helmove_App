import 'package:flutter/material.dart';

import 'package:moto_comm_app_1/core/theme/text_styles.dart';
import 'package:moto_comm_app_1/core/widgets/app_frosted_button.dart';
import 'package:moto_comm_app_1/features/communication/presentation/widgets/rider_card.dart';
import 'package:moto_comm_app_1/features/group_ride/presentation/models/group_ride_args.dart';
import 'package:moto_comm_app_1/features/voice_session/domain/entities/voice_session_entity.dart';

class GroupParticipantsSection extends StatelessWidget {
  final GroupRideArgs data;
  final VoiceSessionEntity? sessionDetails;
  final bool isLoadingSession;
  final int? currentUserId;
  final bool showSettingsButton;
  final Set<String> activeSpeakers;
    final VoidCallback onRefresh;
  final VoidCallback onInvite;
  final VoidCallback onSettings;
  final void Function(int targetUserId, String userName) onKickUser;
  final void Function(int targetUserId, String userName) onMuteUser;
  final void Function(int targetUserId, String userName) onTransferHost;

  const GroupParticipantsSection({
    super.key,
    required this.data,
    required this.sessionDetails,
    required this.isLoadingSession,
    required this.currentUserId,
    required this.showSettingsButton,
    required this.activeSpeakers,
    required this.onRefresh,
    required this.onInvite,
    required this.onSettings,
    required this.onKickUser,
    required this.onMuteUser,
    required this.onTransferHost,
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
            child: Center(
              child: CircularProgressIndicator(),
            ),
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
    final organizerId = data.organizerId;

    RiderRole viewerRole = RiderRole.participant;
    if (currentUserId != null &&
        organizerId != null &&
        currentUserId == organizerId) {
      viewerRole = RiderRole.organizer;
    } else if (currentUserId != null && hostId == currentUserId) {
      viewerRole = RiderRole.host;
    }

    return Column(
      children: participants.map((p) {
        final isConnected = p.status == 'Joined' || p.status == 'Accepted';
        final isMe = p.userId == currentUserId;

        RiderRole role = RiderRole.participant;
        if (organizerId != null && p.userId == organizerId) {
          role = RiderRole.organizer;
        } else if (hostId != null && p.userId == hostId) {
          role = RiderRole.host;
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: RiderCard(
            firstName: p.firstName ?? '',
            lastName: p.lastName ?? '',
            profileImageUrl:
                p.profileImage ?? 'https://i.pravatar.cc/150?u=${p.userId}',
            batteryLevel: isConnected ? 90 : 0,
            signalLevel: isConnected ? 100 : 0,
            isMicOn: isConnected,
            isSpeaking: activeSpeakers.contains(
              p.userId.toString(),
            ),
            isConnected: isConnected,
            isMe: isMe,
            role: role,
            viewerRole: viewerRole,
            onKickUser: ((viewerRole == RiderRole.organizer ||
                        viewerRole == RiderRole.host) &&
                    !isMe)
                ? () => onKickUser(p.userId, p.firstName ?? 'Kullanıcı')
                : null,
            onMuteUser: ((viewerRole == RiderRole.organizer ||
                        viewerRole == RiderRole.host) &&
                    !isMe)
                ? () => onMuteUser(p.userId, p.firstName ?? 'Kullanıcı')
                : null,
            onTransferHost: (viewerRole == RiderRole.organizer && !isMe)
                ? () => onTransferHost(p.userId, p.firstName ?? 'Kullanıcı')
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
