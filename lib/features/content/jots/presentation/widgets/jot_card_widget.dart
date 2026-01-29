import 'package:flutter/material.dart';

class JotCardWidget extends StatelessWidget {
  final String firstName;
  final String lastName;
  final String userName;
  final String content;
  final String profileImage;
  final String timeAgo;
  final String? bikeModel; // Motor modeli opsiyonel

  const JotCardWidget({
    super.key,
    required this.firstName,
    required this.lastName,
    required this.userName,
    required this.content,
    this.profileImage = 'assets/icons/ic_profile.png',
    this.timeAgo = '5dk',
    this.bikeModel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textPrimary = colorScheme.onSurface;
    final textSecondary = colorScheme.onSurface.withValues(alpha: 0.6);

    return InkWell(
      onTap: () {},
      child: Container(
        // İç boşlukları biraz rahatlattık
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: theme.dividerColor.withValues(alpha: 0.2),
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 1. HEADER (PP + İsim + Kullanıcı Adı + Süre) ---
            Row(
              children: [
                // PP Küçültüldü (Radius 20)
                CircleAvatar(
                  radius: 20,
                  backgroundImage: profileImage.startsWith('http')
                      ? NetworkImage(profileImage)
                      : AssetImage(profileImage) as ImageProvider,
                  backgroundColor: colorScheme.surfaceContainerHighest,
                ),
                const SizedBox(width: 10),

                // İsim ve Kullanıcı Bilgileri
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // İsim ve Badge Yan Yana
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              "$firstName $lastName",
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15, // İsim biraz daha kompakt
                              ),
                            ),
                          ),
                          if (bikeModel != null) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.primary.withValues(
                                  alpha: 0.1,
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                bikeModel!,
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.primary,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      // Kullanıcı adı ve Süre
                      Row(
                        children: [
                          Text(
                            "@$userName",
                            style: TextStyle(
                              fontSize: 12,
                              color: textSecondary,
                            ),
                          ),
                          Text(
                            " • $timeAgo",
                            style: TextStyle(
                              fontSize: 12,
                              color: textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Sağ Üst Menü İkonu
                Icon(Icons.more_horiz, size: 20, color: textSecondary),
              ],
            ),

            // --- 2. CONTENT (Tam Genişlik - PP Altından Başlar) ---
            Padding(
              padding: const EdgeInsets.only(
                top: 10,
                bottom: 10,
              ), // Header ile arasına boşluk
              child: Text(
                content,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.4,
                  color: textPrimary.withValues(alpha: 0.9),
                ),
              ),
            ),

            // --- 3. ACTIONS (Butonlar) ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _ActionButton(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: "4",
                  onTap: () {},
                ),
                _ActionButton(
                  icon: Icons.repeat_rounded,
                  label: "2",
                  activeColor: Colors.green,
                  onTap: () {},
                ),
                _ActionButton(
                  icon: Icons.favorite_border_rounded,
                  activeIcon: Icons.favorite_rounded,
                  label: "12",
                  activeColor: Colors.red,
                  onTap: () {},
                ),
                _ActionButton(
                  icon: Icons.bookmark_border_rounded,
                  onTap: () {},
                ),
                _ActionButton(icon: Icons.share_rounded, onTap: () {}),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Aksiyon Butonları (Aynı kaldı, sadece biraz optimize edildi)
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final IconData? activeIcon;
  final String? label;
  final VoidCallback onTap;
  final Color? activeColor;

  const _ActionButton({
    required this.icon,
    this.activeIcon,
    this.label,
    required this.onTap,
    this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(
      context,
    ).colorScheme.onSurface.withValues(alpha: 0.5);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 6.0,
          horizontal: 8.0,
        ), // Tıklama alanı geniş
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: color,
            ), // İkonlar bir tık büyüdü (18->20)
            if (label != null) ...[
              const SizedBox(width: 5),
              Text(label!, style: TextStyle(fontSize: 13, color: color)),
            ],
          ],
        ),
      ),
    );
  }
}
