import 'package:flutter/material.dart';
import '../../../../core/theme/text_styles.dart';

enum RiderRole {
  organizer, // Kurucu (Altın Taç)
  host, // Lider/Atanmış (Gümüş/Mavi Kalkan)
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

    // ESKİ RENK MANTIĞI: Arkaplan Rengi (SurfaceContainerLow + Opacity)
    // Kendi kartımız ise çok hafif bir vurgu (Primary Tint) alabilir ama orijinali bozmadan.
    Color cardColor = isMe
        ? colorScheme.primary.withOpacity(0.08)
        : colorScheme.surfaceContainerLow.withOpacity(0.9);

    return ClipRRect(
      borderRadius: BorderRadius.circular(20), // ESKİ: 20px radius korundu
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            // Konuşuyorsa çerçeve parlasın, değilse silik outline
            color: isSpeaking
                ? Colors.greenAccent.withOpacity(0.6)
                : colorScheme.outline.withOpacity(0.1),
            width: isSpeaking ? 2 : 1,
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
                // 1. SOL: Avatar Bölgesi (Eski tasarım: GreenAccent border)
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
                                  ? "Siz ($firstName)"
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
                          if (role != RiderRole.participant) ...[
                            const SizedBox(width: 6),
                            _buildRoleBadge(),
                          ],
                        ],
                      ),

                      const SizedBox(height: 4),

                      // İstatistikler (Eski MinimalInfo stili ile)
                      Row(
                        children: [
                          _buildMinimalInfo(
                            Icons.signal_cellular_alt,
                            isConnected ? "$signalLevel%" : "---",
                            isConnected
                                ? Colors.greenAccent
                                : colorScheme.error,
                            theme,
                          ),
                          const SizedBox(width: 10),
                          _buildMinimalInfo(
                            Icons.battery_std,
                            "$batteryLevel%",
                            colorScheme.onSurfaceVariant.withOpacity(0.7),
                            theme,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // 3. SAĞ: Aksiyonlar (Eski Buton Stilleriyle)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // --- MİKROFON BUTONU ---
                    // Kendimsem: Tıklanabilir buton
                    // Başkasıysam ve Adminsem: Tıklanabilir (Mute için)
                    // Normal kullanıcıysam: Sadece ikon
                    if (isMe || _canManage(viewerRole, role))
                      _buildActionButton(
                        icon: isMicOn ? Icons.mic : Icons.mic_off,
                        color: isMicOn
                            ? Colors.greenAccent
                            : colorScheme.error.withOpacity(0.8),
                        onTap: onMicPressed,
                        tooltip: "Mikrofon",
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Icon(
                          isMicOn ? Icons.mic : Icons.mic_off,
                          size: 20,
                          color: isMicOn
                              ? Colors.greenAccent.withOpacity(0.7)
                              : colorScheme.error.withOpacity(0.6),
                        ),
                      ),

                    const SizedBox(width: 8),

                    // --- ARKADAŞLIK BUTONU ---
                    // Sadece başkasına bakıyorsam ve arkadaş değilsem
                    if (!isMe && !isFriend)
                      _buildActionButton(
                        icon: Icons.person_add,
                        color: colorScheme.onSurfaceVariant,
                        onTap: onFriendshipPressed,
                        tooltip: "Arkadaş Ekle",
                      )
                    else if (!isMe && isFriend)
                      // Arkadaşsak ufak bir ikonla belirtelim (Buton değil)
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
                    // Sadece yetkim varsa görünür
                    _buildPopupMenu(context),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Avatar Bölgesi (Eski Tasarımın Aynısı)
  Widget _buildAvatarSection(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          // Konuşuyorsa GreenAccent, değilse Transparent
          color: isSpeaking ? Colors.greenAccent : Colors.transparent,
          width: 2.0,
        ),
      ),
      child: Stack(
        children: [
          CircleAvatar(
            radius: 22, // ESKİ: Radius 22
            backgroundImage: NetworkImage(profileImageUrl),
            backgroundColor: colorScheme.surfaceContainerHigh,
            onBackgroundImageError: (_, __) =>
                Icon(Icons.person, color: colorScheme.onSurface),
          ),
          // Online Dot (Opsiyonel, connected ise)
          if (isConnected)
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
        ],
      ),
    );
  }

  // Rol Rozeti (İkonlar)
  Widget _buildRoleBadge() {
    IconData icon;
    Color color;

    switch (role) {
      case RiderRole.organizer:
        icon = Icons.workspace_premium; // Taç
        color = const Color(0xFFFFD700); // Altın Sarısı
        break;
      case RiderRole.host:
        icon = Icons.shield; // Kalkan
        color = Colors.blueAccent; // Mavi/Gümüş
        break;
      default:
        return const SizedBox.shrink();
    }

    return Tooltip(
      message: role == RiderRole.organizer ? "Kurucu" : "Lider",
      child: Icon(icon, size: 18, color: color),
    );
  }

  // Minimal Info (Eski Tasarımın Aynısı)
  Widget _buildMinimalInfo(
    IconData icon,
    String text,
    Color color,
    ThemeData theme,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          text,
          style: AppTextStyles.bodySmall.copyWith(
            color: theme.colorScheme.onSurfaceVariant.withOpacity(0.8),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
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
  bool _canManage(RiderRole viewer, RiderRole target) {
    if (viewer == RiderRole.organizer) return true; // Organizer herkesi yönetir
    if (viewer == RiderRole.host && target == RiderRole.participant) {
      return true; // Host sadece katılımcıları yönetir
    }
    return false;
  }

  // Popup Menü (Sadece yetki varsa dolu gelir)
  Widget _buildPopupMenu(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Yetki yoksa ve kendim değilsem (veya kendimsem bile menü boşsa) gösterme
    if (!_canManage(viewerRole, role) && !isMe) {
      return const SizedBox.shrink(); // Veya Şikayet Et butonu koyulabilir
    }

    // Eğer butonları dolduracak bir aksiyon yoksa hiç çizme
    if (onKickUser == null && onMuteUser == null && onTransferHost == null) {
      return const SizedBox.shrink();
    }

    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_vert,
        color: colorScheme.onSurfaceVariant,
        size: 22,
      ),
      tooltip: "Yönetim",
      padding: EdgeInsets.zero,
      color: colorScheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (value) {
        if (value == 'kick') onKickUser?.call();
        if (value == 'mute') onMuteUser?.call();
        if (value == 'transfer') onTransferHost?.call();
      },
      itemBuilder: (BuildContext context) {
        List<PopupMenuEntry<String>> items = [];

        if (onMuteUser != null) {
          items.add(
            PopupMenuItem(
              value: 'mute',
              child: _buildMenuItem(
                Icons.mic_off,
                "Sustur",
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
                "Oturumdan At",
                colorScheme.error,
              ),
            ),
          );
        }

        if (onTransferHost != null && viewerRole == RiderRole.organizer) {
          items.add(const PopupMenuDivider());
          items.add(
            PopupMenuItem(
              value: 'transfer',
              child: _buildMenuItem(Icons.shield, "Liderlik Ver", Colors.amber),
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
