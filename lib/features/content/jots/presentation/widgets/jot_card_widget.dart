import 'package:flutter/material.dart';
import '../../domain/entities/jot_entity.dart';

class JotCardWidget extends StatelessWidget {
  final JotEntity jot;
  final VoidCallback? onLike;
  final VoidCallback? onComment;
  final VoidCallback? onDelete;
  final bool isCurrentUser;

  const JotCardWidget({
    super.key,
    required this.jot,
    this.onLike,
    this.onComment,
    this.onDelete,
    this.isCurrentUser = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textPrimary = colorScheme.onSurface;
    final textSecondary = colorScheme.onSurface.withOpacity(0.6);

    final firstName = jot.firstName ?? jot.username ?? "Kullanıcı";
    final lastName = jot.lastName ?? "";
    final userName = jot.username ?? "user";
    final content = jot.text ?? "";
    final profileImage =
        jot.userProfilePictureUrl ?? 'assets/icons/ic_profile.png';
    final timeAgo = _formatDate(jot.createdAt);
    final bikeModel = jot.bikeModel;

    return InkWell(
      onTap: () {
        // Maybe open detail page?
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: theme.dividerColor.withOpacity(0.2)),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 1. HEADER ---
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: profileImage.startsWith('http')
                      ? NetworkImage(profileImage)
                      : AssetImage(profileImage) as ImageProvider,
                  backgroundColor: colorScheme.surfaceContainerHighest,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              "$firstName $lastName",
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
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
                                color: colorScheme.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                bikeModel,
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
                if (isCurrentUser)
                  IconButton(
                    icon: Icon(
                      Icons.more_horiz,
                      size: 20,
                      color: textSecondary,
                    ),
                    onPressed:
                        onDelete, // Implement delete menu via parent if complex
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),

            // --- 2. CONTENT ---
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(
                content,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.4,
                  color: textPrimary.withOpacity(0.9),
                ),
              ),
            ),

            // --- 3. ACTIONS ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _ActionButton(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: jot.commentCount.toString(),
                  onTap: onComment ?? () {},
                ),
                _ActionButton(
                  icon: Icons.repeat_rounded,
                  label: "0", // Repost count not in entity yet
                  activeColor: Colors.green,
                  onTap: () {},
                ),
                _ActionButton(
                  icon: Icons
                      .favorite_border_rounded, // TODO: Use isLiked when available
                  activeIcon: Icons.favorite_rounded,
                  label: jot.likeCount.toString(),
                  activeColor: Colors.red,
                  onTap: onLike ?? () {},
                  isActive: jot.isLiked, // Add this when entity supports it
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

  String _formatDate(DateTime? date) {
    if (date == null) return "Şimdi";
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return "Şimdi";
    if (diff.inMinutes < 60) return "${diff.inMinutes}dk";
    if (diff.inHours < 24) return "${diff.inHours}sa";
    return "${diff.inDays}g";
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final IconData? activeIcon;
  final String? label;
  final VoidCallback onTap;
  final Color? activeColor;
  final bool isActive;

  const _ActionButton({
    required this.icon,
    this.activeIcon,
    this.label,
    required this.onTap,
    this.activeColor,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isActive
        ? (activeColor ?? theme.primaryColor)
        : theme.colorScheme.onSurface.withOpacity(0.5);
    final currentIcon = isActive ? (activeIcon ?? icon) : icon;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
        child: Row(
          children: [
            Icon(currentIcon, size: 20, color: color),
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
