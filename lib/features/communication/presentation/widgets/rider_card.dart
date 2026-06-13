import 'package:flutter/material.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../attendance_management/domain/entities/group_role.dart';
import 'package:helmove/l10n/app_localizations.dart';

class RiderCard extends StatelessWidget {
  final String firstName;
  final String lastName;
  final String? profileImageUrl;

  // Durumlar
  final bool isMicOn;
  final bool isSpeaking;
  final bool isFriend;
  final bool isConnected; // Odada mı?
  final bool isMe; // Ben miyim?
  final bool isRemoteMuted; // Admin tarafından mı susturuldu?

  // Roller
  final GroupRole role; // Bu karttaki kullanıcının rolü
  final GroupRole viewerRole; // Bu kartı gören kişinin rolü (Benim rolüm)

  // Aksiyonlar
  final VoidCallback? onMicPressed;
  final VoidCallback? onFriendshipPressed;
  final VoidCallback? onKickUser;
  final VoidCallback? onMuteUser;
  final VoidCallback? onTransferHost;
  final VoidCallback? onPromote;
  final VoidCallback? onDemote;

  const RiderCard({
    super.key,
    required this.firstName,
    required this.lastName,
    this.profileImageUrl,
    this.isMicOn = false,
    this.isSpeaking = false,
    this.isFriend = false,
    this.isConnected = true,
    this.isMe = false,
    this.isRemoteMuted = false,
    this.role = GroupRole.rider,
    this.viewerRole = GroupRole.rider,
    this.onMicPressed,
    this.onFriendshipPressed,
    this.onKickUser,
    this.onMuteUser,
    this.onTransferHost,
    this.onPromote,
    this.onDemote,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // ESKİ RENK MANTIĞI: Arkaplan Rengi (SurfaceContainerLow + Opacity)
    // Kendi kartımız ise çok hafif bir vurgu (Primary Tint) alabilir ama orijinali bozmadan.
    Color cardColor = isMe
        ? colorScheme.primary.withValues(alpha: 0.08)
        : colorScheme.surfaceContainerLow.withValues(alpha: 0.9);

    return ClipRRect(
      borderRadius: BorderRadius.circular(20), // ESKİ: 20px radius korundu
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: colorScheme.outline.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: Padding(
          // ESKİ: Sıkı Padding (8.0) korundu
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
          child: Opacity(
            opacity: isConnected ? 1.0 : 0.5,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 1. SOL: Avatar Bölgesi (Pulse Animasyonlu)
                _buildAvatarSection(colorScheme),

                const SizedBox(width: 12),

                // 2. ORTA: İsim, Rol ve Bilgiler
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // İsim ve Rol Rozeti Satırı
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              isMe
                                  ? "${l10n.you} ($firstName)"
                                  : "$firstName $lastName",
                              style: AppTextStyles.medium.copyWith(
                                // ESKİ: Medium Style
                                color: colorScheme.onSurface,
                                fontSize: 16,
                                letterSpacing: 0.3,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // Rol Rozeti Varsa Göster
                          if (role != GroupRole.rider) ...[
                            const SizedBox(width: 6),
                            _buildRoleBadge(l10n),
                          ],
                        ],
                      ),

                    ],
                  ),
                ),

                // 3. SAĞ: Aksiyonlar (Eski Buton Stilleriyle)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // --- MİKROFON BUTONU (SADECE KENDİ KARTIMIZ, SESTEYKEN) ---
                    // onMicPressed null ise (sese katılmamışsa) gizlenir.
                    if (isMe && onMicPressed != null) ...[
                      _buildActionButton(
                        icon: isRemoteMuted
                            ? Icons.mic_off
                            : (isMicOn ? Icons.mic : Icons.mic_off),
                        color: isRemoteMuted
                            ? colorScheme.error
                            : (isMicOn
                                  ? Colors.greenAccent
                                  : colorScheme.error.withValues(alpha: 0.8)),
                        onTap: isRemoteMuted ? null : onMicPressed,
                        tooltip: isRemoteMuted
                            ? l10n.mutedByAdmin
                            : l10n.microphone,
                      ),
                      const SizedBox(width: 8),
                    ],

                    // --- ARKADAŞLIK BUTONU ---
                    if (!isMe && !isFriend)
                      _buildActionButton(
                        icon: Icons.person_add,
                        color: colorScheme.onSurfaceVariant,
                        onTap: onFriendshipPressed,
                        tooltip: l10n.addFriend,
                      )
                    else if (!isMe && isFriend)
                      const Padding(
                        padding: EdgeInsets.only(right: 8.0),
                        child: Icon(
                          Icons.check_circle,
                          size: 20,
                          color: Colors.greenAccent,
                        ),
                      ),

                    const SizedBox(width: 8),

                    // --- YÖNETİM MENÜSÜ (3 Nokta) ---
                    _buildPopupMenu(context, l10n),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarSection(ColorScheme colorScheme) {
    return _SpeakingPulse(
      isSpeaking: isSpeaking,
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: const BoxDecoration(shape: BoxShape.circle),
        child: Stack(
          children: [
            AppAvatar(
              radius: 22,
              overrideImageUrl: profileImageUrl,
              isCurrentUser: isMe,
            ),
            // Online Dot (Opsiyonel, connected ise)
            if (isConnected && !isRemoteMuted)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: Colors.greenAccent,
                    shape: BoxShape.circle,
                    border: Border.all(color: colorScheme.surface, width: 1.5),
                  ),
                ),
              ),

            // Remote Mute Indicator
            if (isRemoteMuted)
              Positioned(
                right: -2,
                bottom: -2,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: colorScheme.error,
                    shape: BoxShape.circle,
                    border: Border.all(color: colorScheme.surface, width: 2),
                  ),
                  child: const Icon(
                    Icons.mic_off,
                    size: 10,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Rol Rozeti (İkonlar)
  Widget _buildRoleBadge(AppLocalizations l10n) {
    IconData icon;
    Color color;

    switch (role) {
      case GroupRole.admin:
        icon = Icons.workspace_premium; // Taç
        color = const Color(0xFFFFD700); // Altın Sarısı
        break;
      case GroupRole.captain:
        icon = Icons.shield; // Kalkan
        color = Colors.blueAccent; // Mavi/Gümüş
        break;
      default:
        return const SizedBox.shrink();
    }

    return Tooltip(
      message: role == GroupRole.admin ? l10n.adminRole : l10n.captainRole,
      child: Icon(icon, size: 18, color: color),
    );
  }

  // Aksiyon Butonu (Eski Tasarımın Aynısı - Sıkı Padding)
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

  // Yetki Kontrolü
  bool _canManage(GroupRole viewer, GroupRole target) {
    if (viewer == GroupRole.admin) return true; // Admin herkesi yönetir
    if (viewer == GroupRole.captain && target == GroupRole.rider) {
      return true; // Captain sadece Rider'ları yönetir
    }
    return false;
  }

  // Popup Menü (Sadece yetki varsa dolu gelir)
  Widget _buildPopupMenu(BuildContext context, AppLocalizations l10n) {
    final colorScheme = Theme.of(context).colorScheme;

    if (!_canManage(viewerRole, role) && !isMe) {
      return const SizedBox.shrink();
    }

    if (onKickUser == null && onMuteUser == null && onTransferHost == null) {
      return const SizedBox.shrink();
    }

    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_vert,
        color: colorScheme.onSurfaceVariant,
        size: 22,
      ),
      tooltip: l10n.management,
      padding: EdgeInsets.zero,
      color: colorScheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (value) {
        if (value == 'kick') onKickUser?.call();
        if (value == 'mute') onMuteUser?.call();
        if (value == 'transfer') onTransferHost?.call();
        if (value == 'promote') onPromote?.call();
        if (value == 'demote') onDemote?.call();
      },
      itemBuilder: (BuildContext context) {
        List<PopupMenuEntry<String>> items = [];

        if (onMuteUser != null) {
          items.add(
            PopupMenuItem(
              value: 'mute',
              child: _buildMenuItem(
                Icons.mic_off,
                l10n.mute,
                colorScheme.onSurface,
              ),
            ),
          );
        }

        if (onKickUser != null) {
          items.add(
            PopupMenuItem(
              value: 'kick',
              child: _buildMenuItem(
                Icons.person_remove,
                l10n.kickFromSession,
                colorScheme.error,
              ),
            ),
          );
        }

        if (onPromote != null &&
            viewerRole == GroupRole.admin &&
            role == GroupRole.rider) {
          items.add(
            PopupMenuItem(
              value: 'promote',
              child: _buildMenuItem(
                Icons.shield,
                l10n.makeCaptain,
                Colors.blueAccent,
              ),
            ),
          );
        }

        if (onDemote != null &&
            viewerRole == GroupRole.admin &&
            role == GroupRole.captain) {
          items.add(
            PopupMenuItem(
              value: 'demote',
              child: _buildMenuItem(
                Icons.keyboard_arrow_down,
                l10n.demote,
                Colors.orangeAccent,
              ),
            ),
          );
        }

        if (onTransferHost != null && viewerRole == GroupRole.admin) {
          items.add(const PopupMenuDivider());
          items.add(
            PopupMenuItem(
              value: 'transfer',
              child: _buildMenuItem(
                Icons.workspace_premium,
                l10n.transferLeadership,
                Colors.amber,
              ),
            ),
          );
        }

        return items;
      },
    );
  }

  Widget _buildMenuItem(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 12),
        Text(text, style: AppTextStyles.bodyMedium.copyWith(color: color)),
      ],
    );
  }
}

class _SpeakingPulse extends StatefulWidget {
  final Widget child;
  final bool isSpeaking;

  const _SpeakingPulse({required this.child, required this.isSpeaking});

  @override
  State<_SpeakingPulse> createState() => _SpeakingPulseState();
}

class _SpeakingPulseState extends State<_SpeakingPulse>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    if (widget.isSpeaking) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(_SpeakingPulse oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSpeaking != oldWidget.isSpeaking) {
      if (widget.isSpeaking) {
        _controller.repeat();
      } else {
        _controller.stop();
        _controller.reset();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isSpeaking) return widget.child;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Outer Pulse
            Opacity(
              opacity: (1.0 - _controller.value) * 0.7,
              child: Transform.scale(
                scale: 1.0 + (_controller.value * 0.45),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.greenAccent.withValues(alpha: 0.4),
                  ),
                ),
              ),
            ),
            // Inner Pulse
            Opacity(
              opacity: (1.0 - _controller.value) * 0.3,
              child: Transform.scale(
                scale: 1.0 + (_controller.value * 0.25),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.greenAccent.withValues(alpha: 0.2),
                  ),
                ),
              ),
            ),
            child!,
          ],
        );
      },
      child: widget.child,
    );
  }
}
