import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';

enum InviteStatus { none, pending, accepted, rejected }

class InviteRiderCard extends StatelessWidget {
  final String firstName;
  final String lastName;
  final String username;
  final String profileImageUrl;
  final bool isFriend;
  final bool isSelected;
  final InviteStatus inviteStatus;
  final VoidCallback onInviteTap;
  final VoidCallback onFriendshipTap;

  const InviteRiderCard({
    super.key,
    required this.firstName,
    required this.lastName,
    required this.username,
    required this.profileImageUrl,
    required this.isFriend,
    required this.isSelected,
    this.inviteStatus = InviteStatus.none,
    required this.onInviteTap,
    required this.onFriendshipTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLow.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 1. SOL: Avatar
                CircleAvatar(
                  radius: 22,
                  backgroundImage: CachedNetworkImageProvider(profileImageUrl),
                  backgroundColor: colorScheme.surfaceContainerHigh,
                  onBackgroundImageError: (_, _) =>
                      Icon(Icons.person, color: colorScheme.onSurface),
                ),
                const SizedBox(width: 12),

                // 2. ORTA: İsim ve Kullanıcı Adı
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "$firstName $lastName",
                        style: AppTextStyles.medium.copyWith(
                          color: colorScheme.onSurface,
                          fontSize: 16,
                          letterSpacing: 0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "@$username",
                        style: AppTextStyles.bodySmall.copyWith(
                          color: colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.7,
                          ),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                // 3. SAĞ: Aksiyonlar
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Arkadaşlık Butonu
                    _buildActionButton(
                      icon: isFriend ? Icons.person : Icons.person_add,
                      color: isFriend ? Colors.greenAccent : Colors.blueAccent,
                      onTap: onFriendshipTap,
                      tooltip: isFriend ? l10n.friend : l10n.addFriend,
                    ),

                    const SizedBox(width: 8),

                    // Davet Durumu / Davet Butonu
                    _buildInviteAction(colorScheme, l10n),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInviteAction(ColorScheme colorScheme, AppLocalizations l10n) {
    switch (inviteStatus) {
      case InviteStatus.pending:
        return _buildStatusIcon(
          icon: Icons.hourglass_top,
          color: Colors.amber,
          tooltip: l10n.invitation_sent,
        );
      case InviteStatus.accepted:
        return _buildStatusIcon(
          icon: Icons.check_circle,
          color: Colors.greenAccent,
          tooltip: "Davet kabul edildi",
        );
      case InviteStatus.rejected:
      case InviteStatus.none:
        return _buildActionButton(
          icon: isSelected ? Icons.close : Icons.add,
          color: isSelected ? colorScheme.error : colorScheme.primary,
          onTap: onInviteTap,
          tooltip: isSelected ? l10n.remove : l10n.send_invitation,
        );
    }
  }

  // RiderCard'dan kopyalanan aksiyon butonu yapısı
  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback? onTap,
    required String tooltip,
  }) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, color: color, size: 22),
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.symmetric(horizontal: 2.0, vertical: 8.0),
      constraints: const BoxConstraints(),
      style: IconButton.styleFrom(
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  Widget _buildStatusIcon({
    required IconData icon,
    required Color color,
    required String tooltip,
  }) {
    return IconButton(
      onPressed: null,
      icon: Icon(icon, color: color, size: 22),
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.symmetric(horizontal: 2.0, vertical: 8.0),
      constraints: const BoxConstraints(),
      style: IconButton.styleFrom(
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}
