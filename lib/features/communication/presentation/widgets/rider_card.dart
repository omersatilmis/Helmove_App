// ImageFilter için
import 'package:flutter/material.dart';
import '../../../../core/theme/text_styles.dart';

enum RiderRole {
  organizer, // Kurucu (Altın Taç)
  host, // Lider/Atanmış (Gümüş Kalkan) - Şimdilik Organizer ile aynı yetkide olabilir
  participant, // Normal sürücü
}

class RiderCard extends StatelessWidget {
  final String firstName;
  final String lastName;
  final String profileImageUrl;
  final int batteryLevel;
  final int signalLevel;

  // Durumlar
  final bool isMicOn;
  final bool isSpeaking;
  final bool isFriend;
  final bool isConnected; // Odada mı?
  final bool isMe; // Ben miyim?

  // Roller
  final RiderRole role; // Bu karttaki kullanıcının rolü
  final RiderRole viewerRole; // Bu kartı gören kişinin rolü (Benim rolüm)

  // Aksiyonlar
  final VoidCallback? onMicPressed;
  final VoidCallback? onFriendshipPressed;
  final VoidCallback? onKickUser;
  final VoidCallback? onMuteUser;
  final VoidCallback? onTransferHost;

  const RiderCard({
    super.key,
    required this.firstName,
    required this.lastName,
    required this.profileImageUrl,
    this.batteryLevel = 100,
    this.signalLevel = 100,
    this.isMicOn = false,
    this.isSpeaking = false,
    this.isFriend = false,
    this.isConnected = true,
    this.isMe = false,
    this.role = RiderRole.participant,
    this.viewerRole = RiderRole.participant,
    this.onMicPressed,
    this.onFriendshipPressed,
    this.onKickUser,
    this.onMuteUser,
    this.onTransferHost,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Kart Arkaplan Rengi (Rolüne göre hafif tonlama yapılabilir)
    Color cardColor = colorScheme.surfaceContainerLow.withOpacity(0.9);
    if (isMe) {
      cardColor = colorScheme.primary.withOpacity(0.05);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSpeaking
                ? const Color(0xFF22C55E).withOpacity(
                    0.5,
                  ) // Konuşuyorsa yeşil border
                : colorScheme.outline.withOpacity(0.1),
            width: isSpeaking ? 2 : 1,
          ),
          boxShadow: isSpeaking
              ? [
                  BoxShadow(
                    color: const Color(0xFF22C55E).withOpacity(0.2),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Opacity(
            opacity: isConnected ? 1.0 : 0.5,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 1. SOL: Avatar Bölgesi
                _buildAvatarSection(colorScheme),

                const SizedBox(width: 12),

                // 2. ORTA: İsim, Rol ve Bilgiler
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // İsim ve Rozet Satırı
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              isMe
                                  ? "Siz ($firstName)"
                                  : "$firstName $lastName",
                              style: AppTextStyles.bodyLarge.copyWith(
                                color: colorScheme.onSurface,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (role != RiderRole.participant) ...[
                            const SizedBox(width: 6),
                            _buildRoleBadge(context),
                          ],
                        ],
                      ),

                      const SizedBox(height: 6),

                      // İstatistikler (Pil, Sinyal)
                      Row(
                        children: [
                          _buildStatusPill(
                            context,
                            icon: Icons.signal_cellular_alt,
                            text: isConnected ? "$signalLevel%" : "Koptu",
                            color: isConnected
                                ? Colors.green
                                : colorScheme.error,
                          ),
                          const SizedBox(width: 8),
                          _buildStatusPill(
                            context,
                            icon: Icons.battery_std,
                            text: "$batteryLevel%",
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // 3. SAĞ: Aksiyonlar & Menü
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Mic Durumu (Sadece gösterge veya kendi mic'im ise buton)
                    if (isMe)
                      _buildActionButton(
                        icon: isMicOn ? Icons.mic : Icons.mic_off,
                        color: isMicOn
                            ? const Color(0xFF22C55E)
                            : colorScheme.error,
                        onTap: onMicPressed,
                        tooltip: "Mikrofonu Aç/Kapat",
                        filled: true,
                      )
                    else
                      // Başkası ise sadece ikon
                      Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Icon(
                          isMicOn ? Icons.mic : Icons.mic_off,
                          size: 20,
                          color: isMicOn
                              ? colorScheme.onSurfaceVariant.withOpacity(0.6)
                              : colorScheme.error.withOpacity(0.6),
                        ),
                      ),

                    if (!isMe) ...[
                      const SizedBox(width: 4),
                      // Arkadaş Ekle (Eğer arkadaş değilse)
                      if (!isFriend)
                        _buildActionButton(
                          icon: Icons.person_add,
                          color: colorScheme.primary,
                          onTap: onFriendshipPressed,
                          tooltip: "Arkadaş Ekle",
                        ),

                      const SizedBox(width: 4),

                      // 3 Nokta Menü
                      _buildPopupMenu(context),
                    ],
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
    return Stack(
      children: [
        // Avatar Çerçevesi (Konuşma Efekti)
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: isSpeaking ? const Color(0xFF22C55E) : Colors.transparent,
              width: 2.5,
            ),
          ),
          child: CircleAvatar(
            radius: 24,
            backgroundImage: NetworkImage(profileImageUrl),
            backgroundColor: colorScheme.surfaceContainerHigh,
            onBackgroundImageError: (_, __) =>
                Icon(Icons.person, color: colorScheme.onSurface),
          ),
        ),

        // Online Göstergesi (Sağ Alt)
        if (isConnected)
          Positioned(
            right: 2,
            bottom: 2,
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: const Color(0xFF22C55E),
                shape: BoxShape.circle,
                border: Border.all(color: colorScheme.surface, width: 2),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildRoleBadge(BuildContext context) {
    IconData icon;
    Color color;
    String tooltip;

    switch (role) {
      case RiderRole.organizer:
        icon = Icons.workspace_premium; // Taç
        color = const Color(0xFFFFD700); // Altın
        tooltip = "Kurucu";
        break;
      case RiderRole.host:
        icon = Icons.shield; // Kalkan
        color = const Color(0xFFC0C0C0); // Gümüş/Mavi
        tooltip = "Lider";
        break;
      default:
        return const SizedBox.shrink();
    }

    return Tooltip(
      message: tooltip,
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }

  Widget _buildStatusPill(
    BuildContext context, {
    required IconData icon,
    required String text,
    required Color color,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color.withOpacity(0.8)),
          const SizedBox(width: 4),
          Text(
            text,
            style: AppTextStyles.bodySmall.copyWith(
              fontSize: 10,
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback? onTap,
    required String tooltip,
    bool filled = false,
  }) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, color: filled ? Colors.white : color, size: 20),
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      style: IconButton.styleFrom(
        backgroundColor: filled ? color : null,
        highlightColor: color.withOpacity(0.1),
      ),
    );
  }

  Widget _buildPopupMenu(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Yetki Kontrolü:
    // Eğer ben Organizer isem, herkese her şeyi yapabilirim (kendim hariç).
    // Eğer ben Host isem, Participantları yönetebilirim.

    bool canManage = false;
    if (viewerRole == RiderRole.organizer) canManage = true;
    if (viewerRole == RiderRole.host && role == RiderRole.participant)
      canManage = true;

    // Eğer yetkim yoksa ve sadece "Profil Görüntüle" vs varsa menü gösterilebilir.
    // Şimdilik sadece yönetimsel aksiyonlar tanımlı.

    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_vert,
        color: colorScheme.onSurfaceVariant,
        size: 22,
      ),
      tooltip: "Seçenekler",
      padding: EdgeInsets.zero,
      color: colorScheme.surfaceContainerHigh,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (value) {
        if (value == 'kick') onKickUser?.call();
        if (value == 'mute') onMuteUser?.call();
        if (value == 'transfer') onTransferHost?.call();
      },
      itemBuilder: (BuildContext context) {
        final List<PopupMenuEntry<String>> items = [];

        if (canManage) {
          if (onMuteUser != null) {
            items.add(
              PopupMenuItem<String>(
                value: 'mute',
                child: _buildMenuItem(
                  context,
                  Icons.mic_off,
                  "Sustur",
                  colorScheme.onSurface,
                ),
              ),
            );
          }
          if (onKickUser != null) {
            items.add(
              PopupMenuItem<String>(
                value: 'kick',
                child: _buildMenuItem(
                  context,
                  Icons.person_remove,
                  "Oturumdan At",
                  colorScheme.error,
                ),
              ),
            );
          }
          if (onTransferHost != null && viewerRole == RiderRole.organizer) {
            // Sadece Organizer devreder varsayımı (veya Host da edebilir backend izin veriyorsa)
            items.add(const PopupMenuDivider());
            items.add(
              PopupMenuItem<String>(
                value: 'transfer',
                child: _buildMenuItem(
                  context,
                  Icons.shield,
                  "Liderliği Devret",
                  Colors.amber,
                ),
              ),
            );
          }
        } else {
          // Normal Kullanıcı Görünümü
          items.add(
            PopupMenuItem<String>(
              value: 'report', // Henüz fonksiyonel değil
              child: _buildMenuItem(
                context,
                Icons.flag,
                "Şikayet Et",
                colorScheme.onSurface,
              ),
            ),
          );
        }

        return items;
      },
    );
  }

  Widget _buildMenuItem(
    BuildContext context,
    IconData icon,
    String text,
    Color color,
  ) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 12),
        Text(text, style: AppTextStyles.bodyMedium.copyWith(color: color)),
      ],
    );
  }
}
