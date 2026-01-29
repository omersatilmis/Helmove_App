import 'package:flutter/material.dart';
import '../../../../../../core/theme/app_text_styles.dart';

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
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      // Kartlar arası boşluk daha az, daha kompakt
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        // Sadece alt tarafa ince bir çizgi (Instagram/Twitter tarzı)
        border: Border(
          bottom: BorderSide(
            color: theme.dividerColor.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Row(
          children: [
            // 1. AVATAR (Biraz daha küçük ve zarif)
            CircleAvatar(
              radius: 22,
              backgroundColor: colorScheme.surfaceContainerHighest,
              backgroundImage: imageUrl.isNotEmpty
                  ? NetworkImage(imageUrl)
                  : null,
              child: imageUrl.isEmpty
                  ? Text(
                      firstName.isNotEmpty ? firstName[0].toUpperCase() : "?",
                      style: TextStyle(color: colorScheme.onSurfaceVariant),
                    )
                  : null,
            ),

            const SizedBox(width: 16),

            // 2. İSİM VE BİLGİ (Geniş Alan)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // İsim
                  Text(
                    "$firstName $lastName",
                    style: AppTextStyles.bold.copyWith(
                      fontSize: 15,
                      color: colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  // Kullanıcı Adı ve Durum tek satırda
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          "@$username",
                          style: AppTextStyles.medium.copyWith(
                            fontSize: 13,
                            color: colorScheme.onSurface.withOpacity(0.5),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Araya nokta koyup durumu yazıyoruz
                      if (statusInfo.isNotEmpty) ...[
                        Text(
                          " • $statusInfo",
                          style: AppTextStyles.medium.copyWith(
                            fontSize: 12,
                            color: colorScheme.onSurface.withOpacity(0.4),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // 3. AKSİYON BUTONLARI (Minimalize edilmiş)
            _buildMinimalActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildMinimalActions(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    switch (type) {
      case FriendshipCardType.friends:
        // Sadece Mesaj ikonu ve 3 nokta.
        // "Sil" gibi yıkıcı işlemler 3 noktanın içinde olmalı.
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: onMessageTap,
              icon: Icon(Icons.chat_bubble_outline_rounded),
              color: colorScheme.primary,
              iconSize: 22,
              tooltip: "Mesaj",
              constraints: const BoxConstraints(),
              padding: const EdgeInsets.all(8),
            ),
            IconButton(
              onPressed: onOptionsTap,
              icon: Icon(Icons.delete),
              color: colorScheme.onSurface.withOpacity(0.6),
              iconSize: 22,
              tooltip: "Sil",
              constraints: const BoxConstraints(),
              padding: const EdgeInsets.all(8),
            ),
          ],
        );

      case FriendshipCardType.discover:
        // Net bir "Ekle" butonu. İkon yerine küçük bir buton daha iyi dönüşüm sağlar.
        return SizedBox(
          height: 32,
          child: FilledButton.tonal(
            onPressed: onAddFriendTap,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            child: const Text("Ekle", style: TextStyle(fontSize: 13)),
          ),
        );

      case FriendshipCardType.sent:
        // Sadece "Bekliyor" yazısı veya pasif bir ikon. Butona gerek yok.
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            "Bekliyor",
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        );

      case FriendshipCardType.received:
        // Kabul et (Belirgin) / Reddet (Silik)
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Reddet (Küçük X)
            InkWell(
              onTap: onRejectTap,
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Icon(
                  Icons.close_rounded,
                  size: 20,
                  color: colorScheme.error.withOpacity(0.8),
                ),
              ),
            ),
            const SizedBox(width: 4),
            // Kabul Et (Buton şeklinde)
            SizedBox(
              height: 32,
              child: FilledButton(
                onPressed: onAcceptTap,
                style: FilledButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                child: const Text("Kabul", style: TextStyle(fontSize: 13)),
              ),
            ),
          ],
        );
    }
  }
}
