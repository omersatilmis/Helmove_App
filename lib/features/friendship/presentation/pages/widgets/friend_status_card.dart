import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../../../core/theme/text_styles.dart';
import '../../../../../../core/widgets/app_button.dart';

enum FriendshipCardType { friends, sent, received, discover }

class FriendStatusCard extends StatelessWidget {
  final String imageUrl;
  final String firstName;
  final String lastName;
  final String username;
  final String statusInfo; // "2s önce" gibi kısa tutulmalı
  final FriendshipCardType type;

  // Callbackler
  final VoidCallback? onMessageTap;
  final VoidCallback? onOptionsTap; // 3 nokta menüsü için
  final VoidCallback? onAcceptTap;
  final VoidCallback? onRejectTap;
  final VoidCallback? onAddFriendTap;
  final VoidCallback? onCardTap; // Kartın tamamına tıklayınca
  final bool showActions; // Aksiyon butonlarını göster/gizle

  const FriendStatusCard({
    super.key,
    required this.imageUrl,
    required this.firstName,
    required this.lastName,
    required this.username,
    required this.statusInfo,
    required this.type,
    this.onMessageTap,
    this.onOptionsTap,
    this.onAcceptTap,
    this.onRejectTap,
    this.onAddFriendTap,
    this.onCardTap,
    this.showActions = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.dividerColor.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: InkWell(
        onTap: onCardTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          child: Row(
            children: [
              // 1. AVATAR
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: colorScheme.primary.withValues(alpha: 0.2),
                    width: 2,
                  ),
                ),
                child: CircleAvatar(
                  radius: 22,
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  backgroundImage: imageUrl.isNotEmpty
                      ? CachedNetworkImageProvider(imageUrl)
                      : null,
                  child: imageUrl.isEmpty
                      ? Text(
                          firstName.isNotEmpty ? firstName[0].toUpperCase() : "?",
                          style: TextStyle(color: colorScheme.onSurfaceVariant),
                        )
                      : null,
                ),
              ),

              const SizedBox(width: 16),

              // 2. İSİM VE BİLGİ
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "$firstName $lastName",
                      style: AppTextStyles.bold.copyWith(
                        fontSize: 15,
                        color: colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            "@$username",
                            style: AppTextStyles.medium.copyWith(
                              fontSize: 13,
                              color: colorScheme.onSurface.withValues(alpha: 0.5),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (statusInfo.isNotEmpty) ...[
                          Text(
                            " • $statusInfo",
                            style: AppTextStyles.medium.copyWith(
                              fontSize: 12,
                              color: colorScheme.onSurface.withValues(alpha: 0.4),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // 3. AKSİYON BUTONLARI
              if (showActions) _buildMinimalActions(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMinimalActions(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    switch (type) {
      case FriendshipCardType.friends:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: onMessageTap,
              icon: const Icon(Icons.chat_bubble_outline_rounded),
              color: colorScheme.primary,
              iconSize: 22,
              tooltip: "Mesaj",
              constraints: const BoxConstraints(),
              padding: const EdgeInsets.all(8),
            ),
            IconButton(
              onPressed: onOptionsTap,
              icon: const Icon(Icons.delete_outline_rounded),
              color: colorScheme.error.withValues(alpha: 0.7),
              iconSize: 22,
              tooltip: "Sil",
              constraints: const BoxConstraints(),
              padding: const EdgeInsets.all(8),
            ),
          ],
        );

      case FriendshipCardType.discover:
        return AppButton(
          text: "Ekle",
          onPressed: onAddFriendTap,
          variant: AppButtonVariant.primary,
          style: AppButtonStyle.filled,
          size: AppButtonSize.small,
          width: 70,
        );

      case FriendshipCardType.sent:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            "Bekliyor",
            style: AppTextStyles.medium.copyWith(
              fontSize: 12,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        );

      case FriendshipCardType.received:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppButton(
              text: "Reddet",
              onPressed: onRejectTap,
              variant: AppButtonVariant.danger,
              style: AppButtonStyle.text,
              size: AppButtonSize.small,
              width: 70,
            ),
            const SizedBox(width: 8),
            AppButton(
              text: "Kabul",
              onPressed: onAcceptTap,
              variant: AppButtonVariant.primary,
              style: AppButtonStyle.filled,
              size: AppButtonSize.small,
              width: 70,
            ),
          ],
        );
    }
  }
}
