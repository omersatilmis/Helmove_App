import 'package:flutter/material.dart';

import 'package:helmove/core/theme/text_styles.dart';
import 'package:helmove/core/widgets/app_frosted_button.dart';
import 'package:helmove/features/communication/presentation/widgets/rider_card.dart';
import 'package:helmove/features/group_ride/presentation/models/group_ride_args.dart';
import 'package:helmove/features/intercom/domain/intercom_models.dart';
import 'package:helmove/features/voice_session/domain/entities/voice_session_entity.dart';
import 'package:helmove/features/attendance_management/domain/entities/group_role.dart';
import 'package:helmove/l10n/app_localizations.dart';

class GroupParticipantsSection extends StatelessWidget {
  final GroupRideArgs data;
  final VoiceSessionEntity? sessionDetails;
  final bool isLoadingSession;
  final int? currentUserId;
  final bool showSettingsButton;
  final Set<String> activeSpeakers;
  final Map<int, IntercomConnectionQuality> participantQualities;
  final bool isCurrentUserMicOn;

  /// [ODA MODELİ] Kullanıcı ses kanalında mı? Mikrofon toggle'ı yalnızca
  /// sesteyken (kendi kartında) gösterilir.
  final bool isInVoice;
  final VoidCallback onToggleMic;
  final VoidCallback? onRefresh;
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
    required this.isInVoice,
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
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.connectedRiders,
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
          _buildParticipantList(context, l10n),
      ],
    );
  }

  Widget _buildParticipantList(BuildContext context, AppLocalizations l10n) {
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

    if (participants.isEmpty) return _buildEmptyState(context, l10n);

    final hostId = sessionDetails?.adminId;

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

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: participants.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final participant = participants[index];
        final isConnected =
            participant.status == 'Joined' || participant.status == 'Accepted';
        final isMe = participant.userId == currentUserId;
        final role = participant.role;

        return RiderCard(
          key: ValueKey(participant.userId),
          firstName: participant.firstName ?? '',
          lastName: participant.lastName ?? '',
          profileImageUrl: participant.profileImage,
          isMicOn: isMe ? isCurrentUserMicOn : false,
          isSpeaking: activeSpeakers.contains(participant.userId.toString()),
          isConnected: isConnected,
          isMe: isMe,
          isRemoteMuted: participant.isRemoteMuted,
          role: role,
          viewerRole: viewerRole,
          onMicPressed: (isMe && isInVoice) ? onToggleMic : null,
          onKickUser:
              ((viewerRole == GroupRole.admin ||
                      viewerRole == GroupRole.captain) &&
                  !isMe)
              ? () => onKickUser(
                  participant.userId,
                  participant.firstName ?? l10n.defaultUserName,
                )
              : null,
          onMuteUser:
              ((viewerRole == GroupRole.admin ||
                      viewerRole == GroupRole.captain) &&
                  !isMe)
              ? () => onMuteUser(
                  participant.userId,
                  participant.firstName ?? l10n.defaultUserName,
                )
              : null,
          onTransferHost: (viewerRole == GroupRole.admin && !isMe)
              ? () => onTransferHost(
                  participant.userId,
                  participant.firstName ?? l10n.defaultUserName,
                )
              : null,
          onPromote:
              (viewerRole == GroupRole.admin &&
                  participant.role == GroupRole.rider &&
                  !isMe)
              ? () => onPromote(
                  participant.userId,
                  participant.firstName ?? l10n.defaultUserName,
                )
              : null,
          onDemote:
              (viewerRole == GroupRole.admin &&
                  participant.role == GroupRole.captain &&
                  !isMe)
              ? () => onDemote(
                  participant.userId,
                  participant.firstName ?? l10n.defaultUserName,
                )
              : null,
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, AppLocalizations l10n) {
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
              l10n.noParticipantsYet,
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
