import 'dart:ui'; // ImageFilter için
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
  final VoidCallback? onMicPressed;
  final VoidCallback? onFriendshipPressed;
  final VoidCallback? onMenuPressed;

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
    this.onMicPressed,
    this.onFriendshipPressed,
    this.onMenuPressed,
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
          color: colorScheme.surfaceContainerLow.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: colorScheme.outline.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Padding(
            // KENAR BOŞLUKLARI AZALTILDI (16 -> 8)
            padding: const EdgeInsets.symmetric(
              horizontal: 8.0,
              vertical: 12.0,
            ),
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
                            "$signalLevel%",
                            Colors.greenAccent,
                            theme,
                          ),
                          const SizedBox(width: 10), // Yatay boşluk azaltıldı
                          _buildMinimalInfo(
                            Icons.battery_std,
                            "$batteryLevel%",
                            colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
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
                          : colorScheme.error.withValues(alpha: 0.8),
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

                    _buildActionButton(
                      icon: Icons.more_vert,
                      color: colorScheme.onSurfaceVariant,
                      onTap: onMenuPressed,
                      tooltip: "Menü",
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
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
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
