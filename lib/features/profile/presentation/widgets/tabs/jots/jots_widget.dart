import 'package:flutter/material.dart';
import 'package:moto_comm_app_1/core/theme/text_styles.dart';

class JotCardWidget extends StatelessWidget {
  final String firstName;
  final String lastName;
  final String userName;
  final String content;
  final String profileImage;
  final String timeAgo;

  const JotCardWidget({
    super.key,
    required this.firstName,
    required this.lastName,
    required this.userName,
    required this.content,
    this.profileImage = 'assets/icons/ic_profile.png',
    this.timeAgo = '5m',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: theme.dividerColor.withValues(alpha: 0.1)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- HEADER: PP, İSİM, SEÇENEKLER ---
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundImage: AssetImage(profileImage),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          "$firstName $lastName",
                          style: AppTextStyles.h3.copyWith(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "• $timeAgo",
                          style: AppTextStyles.bodySmall.copyWith(color: onSurface.withValues(alpha: 0.5)),
                        ),
                      ],
                    ),
                    Text(
                      "@$userName",
                      style: AppTextStyles.bodySmall.copyWith(color: onSurface.withValues(alpha: 0.6)),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.more_horiz_rounded, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),

          // --- CONTENT: METİN ALANI ---
          Padding(
            padding: const EdgeInsets.only(left: 56, top: 4, bottom: 12),
            child: Text(
              content,
              style: AppTextStyles.thin.copyWith(
                fontSize: 15,
                height: 1.4,
                color: onSurface.withValues(alpha: 0.9),
              ),
            ),
          ),

          // --- ACTIONS: BEĞEN, YORUM, PAYLAŞ, GÖNDER, KAYDET ---
          Padding(
            padding: const EdgeInsets.only(left: 48),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _ActionButton(icon: Icons.favorite_border_rounded, label: "12", onTap: () {}),
                _ActionButton(icon: Icons.chat_bubble_outline_rounded, label: "4", onTap: () {}),
                _ActionButton(icon: Icons.repeat_rounded, label: "2", onTap: () {}),
                _ActionButton(icon: Icons.send_rounded, onTap: () {}),
                _ActionButton(icon: Icons.bookmark_border_rounded, onTap: () {}),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Alt Butonlar İçin Küçük Yardımcı Widget
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String? label;
  final VoidCallback onTap;

  const _ActionButton({required this.icon, this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            if (label != null) ...[
              const SizedBox(width: 4),
              Text(label!, style: TextStyle(fontSize: 12, color: color)),
            ],
          ],
        ),
      ),
    );
  }
}
