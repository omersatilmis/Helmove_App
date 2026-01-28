import 'package:flutter/material.dart';
import '../../../../../../core/theme/app_text_styles.dart';

/// Kartın hangi modda çalışacağını belirleyen Enum
enum FriendshipCardType {
  friends, // Mevcut Arkadaşlar
  sent, // Gönderilen İstek (Beklemede)
  received, // Gelen İstek (Onay Bekliyor)
  discover, // Keşfet (Arkadaş Değil)
}

class FriendStatusCard extends StatelessWidget {
  final int index; // Sıra No
  final String imageUrl;
  final String firstName;
  final String lastName;
  final String username;
  final String statusInfo; // Örn: "2 saat önce", "İstek gönderildi"
  final FriendshipCardType type;

  // --- AKSİYON CALLBACKLERİ ---
  final VoidCallback? onMessageTap; // Hepsinde ortak
  final VoidCallback? onOptionsTap; // Arkadaşlar için
  final VoidCallback? onRemoveTap; // Arkadaşlıktan çıkar
  final VoidCallback? onCancelRequestTap; // İsteği iptal et
  final VoidCallback? onAcceptTap; // İsteği kabul et
  final VoidCallback? onRejectTap; // İsteği reddet
  final VoidCallback? onAddFriendTap; // Arkadaş Ekle (Keşfet)

  const FriendStatusCard({
    super.key,
    required this.index,
    required this.imageUrl,
    required this.firstName,
    required this.lastName,
    required this.username,
    required this.statusInfo,
    required this.type,
    this.onMessageTap,
    this.onOptionsTap,
    this.onRemoveTap,
    this.onCancelRequestTap,
    this.onAcceptTap,
    this.onRejectTap,
    this.onAddFriendTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20), // Modern oval köşeler
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // 1. SIRA NUMARASI
              Text(
                "${index + 1}.",
                style: AppTextStyles.bold.copyWith(
                  fontSize: 16,
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(width: 10),

              // 2. PROFIL FOTOĞRAFI
              CircleAvatar(
                radius: 24,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                backgroundImage: imageUrl.isNotEmpty
                    ? NetworkImage(imageUrl)
                    : null,
                child: imageUrl.isEmpty
                    ? Text(firstName.isNotEmpty ? firstName[0] : "?")
                    : null,
              ),
              const SizedBox(width: 12),

              // 3. İSİM VE KULLANICI ADI
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "$firstName $lastName",
                      style: AppTextStyles.bold.copyWith(fontSize: 16),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      "@$username",
                      style: AppTextStyles.medium.copyWith(
                        fontSize: 13,
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // 4. DURUM BUTONLARI (SAĞ TARAF)
              _buildActionButtons(theme),
            ],
          ),

          // 5. DURUM BİLGİSİ (ALT KISIM)
          // Profil fotoğrafının hizasından başlaması için padding verdik
          Padding(
            padding: const EdgeInsets.only(left: 46, top: 6),
            child: Text(
              statusInfo,
              style: AppTextStyles.thin.copyWith(
                fontSize: 12,
                color: theme.colorScheme.secondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Kart tipine göre 3'lü ikon setini oluşturur
  Widget _buildActionButtons(ThemeData theme) {
    switch (type) {
      case FriendshipCardType.friends:
        // DURUM 1: ARKADAŞLAR
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ActionButton(
              icon: Icons.chat_bubble_outline_rounded,
              color: Colors.blueAccent,
              onTap: onMessageTap,
              tooltip: "Mesaj",
            ),
            _ActionButton(
              icon: Icons.person_remove_outlined,
              color: Colors.redAccent,
              onTap: onRemoveTap,
              tooltip: "Çıkar",
            ),
            _ActionButton(
              icon: Icons.more_vert_rounded,
              color: theme.colorScheme.onSurfaceVariant,
              onTap: onOptionsTap,
              tooltip: "Seçenekler",
            ),
          ],
        );

      case FriendshipCardType.sent:
        // DURUM 2: BEKLEYEN (GÖNDERİLEN)
        // Not: İptal butonu kaldırıldı - backend endpoint mevcut değil
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ActionButton(
              icon: Icons.chat_bubble_outline_rounded,
              color: Colors.blueAccent,
              onTap: onMessageTap,
              tooltip: "Mesaj",
            ),
            // Sadece görsel ikon (Tıklanmaz, durum belirtir)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Icon(
                Icons.access_time_rounded,
                color: Colors.orangeAccent,
                size: 22,
              ),
            ),
            // İptal butonu devre dışı - backend endpoint eklenince aktifleştirilecek
          ],
        );

      case FriendshipCardType.received:
        // DURUM 3: GELEN İSTEK
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ActionButton(
              icon: Icons.chat_bubble_outline_rounded,
              color: Colors.blueAccent,
              onTap: onMessageTap,
              tooltip: "Mesaj",
            ),
            _ActionButton(
              icon: Icons.check_circle_outline_rounded, // Ekle Tıkı
              color: Colors.green,
              onTap: onAcceptTap,
              tooltip: "Kabul Et",
            ),
            _ActionButton(
              icon: Icons.highlight_off_rounded, // Reddet Çarpısı
              color: Colors.redAccent,
              onTap: onRejectTap,
              tooltip: "Reddet",
            ),
          ],
        );

      case FriendshipCardType.discover:
        // DURUM 4: KEŞFET (ARKADAŞ EKLE)
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ActionButton(
              icon: Icons.person_add_rounded,
              color:
                  theme.colorScheme.primary, // Tema rengi (Turuncu/Mavi neyse)
              onTap: onAddFriendTap,
              tooltip: "Arkadaş Ekle",
            ),
          ],
        );
    }
  }
}

/// Kod tekrarını önlemek için özel mini buton widget'ı
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final String tooltip;

  const _ActionButton({
    required this.icon,
    required this.color,
    required this.onTap,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      clipBehavior: Clip.hardEdge,
      child: Tooltip(
        message: tooltip,
        child: IconButton(
          onPressed: onTap,
          icon: Icon(icon, size: 24), // İkon boyutu
          color: color,
          padding: const EdgeInsets.all(6), // Tıklama alanı genişliği
          constraints: const BoxConstraints(), // Sıkışık düzen için
          splashRadius: 20,
        ),
      ),
    );
  }
}
