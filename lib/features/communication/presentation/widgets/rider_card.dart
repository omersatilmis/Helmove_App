// ImageFilter için
import 'package:flutter/material.dart';
import '../../../../core/theme/text_styles.dart';

class RiderCard extends StatelessWidget {
  final String firstName;
  final String lastName;
  final String profileImageUrl;
  final int batteryLevel;
  final int signalLevel;
  final bool isMicOn;
  final bool isSpeaking;
  final bool isFriend;
  final bool isConnected; // Intercom ses bağlantısını temsil eder
  final VoidCallback? onMicPressed;
  final VoidCallback? onFriendshipPressed;
  // Menü Aksiyonları (Sadece Host İse Dolu Gelecek)
  final VoidCallback? onKickUser;
  final VoidCallback? onMuteUser;
  final VoidCallback? onTransferHost;

  const RiderCard({
    super.key,
    required this.firstName,
    required this.lastName,
    required this.profileImageUrl,
    this.batteryLevel = 76,
    this.signalLevel = 95,
    this.isMicOn = false,
    this.isSpeaking = false,
    this.isFriend = false,
    this.isConnected = true, // Varsayılan bağlı kabul edelim
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

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow.withOpacity(0.9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: colorScheme.outline.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Padding(
          // KENAR BOŞLUKLARI AZALTILDI (16 -> 8)
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
          child: Opacity(
            opacity: isConnected ? 1.0 : 0.5,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 1. SOL: Avatar (En sola yaslı)
                _buildAvatarSection(colorScheme),

                // Avatar ile yazı arası boşluk (biraz daha sıkı)
                const SizedBox(width: 10),

                // 2. ORTA: İsim ve İstatistikler (Aradaki tüm boşluğu kaplar)
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "$firstName $lastName",
                        style: AppTextStyles.medium.copyWith(
                          color: colorScheme.onSurface,
                          //fontWeight: FontWeight.w600,
                          fontSize: 16,
                          letterSpacing: 0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4), // Dikey boşluk azaltıldı
                      Row(
                        children: [
                          _buildMinimalInfo(
                            Icons.signal_cellular_alt,
                            isConnected ? "$signalLevel%" : "Bağlantı Yok",
                            isConnected
                                ? Colors.greenAccent
                                : colorScheme.error,
                            theme,
                          ),
                          const SizedBox(width: 10), // Yatay boşluk azaltıldı
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

                // BURADAKİ SIZEDBOX KALDIRILDI, Expanded direkt itecek.

                // 3. SAĞ: Aksiyonlar (En sağa yaslı)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildActionButton(
                      icon: isMicOn ? Icons.mic : Icons.mic_off,
                      color: isMicOn
                          ? Colors.greenAccent
                          : colorScheme.error.withOpacity(0.8),
                      onTap: onMicPressed,
                      tooltip: "Mikrofon",
                    ),

                    const SizedBox(width: 8),

                    _buildActionButton(
                      icon: isFriend ? Icons.check_circle : Icons.person_add,
                      color: isFriend
                          ? Colors.greenAccent
                          : colorScheme.onSurfaceVariant,
                      onTap: onFriendshipPressed,
                      tooltip: "Arkadaşlık",
                    ),

                    const SizedBox(width: 8),

                    // 3 nokta menüsü - Sadece yetki varsa (callbackler doluysa) gösterilir veya pasif olur
                    if (onKickUser != null ||
                        onMuteUser != null ||
                        onTransferHost != null)
                      PopupMenuButton<String>(
                        icon: Icon(
                          Icons.more_vert,
                          color: colorScheme.onSurfaceVariant,
                          size: 22,
                        ),
                        tooltip: "Yönetim",
                        padding: EdgeInsets.zero,
                        color: colorScheme.surfaceContainerHigh,
                        onSelected: (value) {
                          if (value == 'kick') onKickUser?.call();
                          if (value == 'mute') onMuteUser?.call();
                          if (value == 'transfer') onTransferHost?.call();
                        },
                        itemBuilder: (BuildContext context) =>
                            <PopupMenuEntry<String>>[
                              if (onMuteUser != null)
                                PopupMenuItem<String>(
                                  value: 'mute',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.mic_off,
                                        color: colorScheme.onSurface,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        "Sustur",
                                        style: AppTextStyles.bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                              if (onKickUser != null)
                                PopupMenuItem<String>(
                                  value: 'kick',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.person_remove,
                                        color: colorScheme.error,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        "Oturumdan At",
                                        style: AppTextStyles.bodySmall.copyWith(
                                          color: colorScheme.error,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              if (onTransferHost != null)
                                PopupMenuItem<String>(
                                  value: 'transfer',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.admin_panel_settings,
                                        color: Colors.amber,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        "Host Devret",
                                        style: AppTextStyles.bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Minimal Avatar
  Widget _buildAvatarSection(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(2), // Border mesafesi azaltıldı (3 -> 2)
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isSpeaking ? Colors.greenAccent : Colors.transparent,
          width: 2.0,
        ),
      ),
      child: CircleAvatar(
        radius: 22,
        backgroundImage: NetworkImage(profileImageUrl),
        backgroundColor: colorScheme.surfaceContainerHigh,
        onBackgroundImageError: (_, __) =>
            Icon(Icons.person, color: colorScheme.onSurface),
      ),
    );
  }

  // Minimal Bilgi Satırı
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

  // Minimal Aksiyon Butonu (Daha sıkı)
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
      // BUTONLARIN KENDİ İÇ BOŞLUĞU AZALTILDI (all(8) -> horizontal(2))
      padding: const EdgeInsets.symmetric(horizontal: 2.0, vertical: 8.0),
      constraints: const BoxConstraints(),
      style: IconButton.styleFrom(
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}
