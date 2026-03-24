import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:helmove/core/theme/text_styles.dart';

class PoiBusinessCard extends StatelessWidget {
  final String title;
  final String distance; // Kalan mesafe
  final String? imageUrl; // İşletmenin görseli
  final VoidCallback? onDirectionsTap; // Yol tarifi aksiyonu
  final VoidCallback? onAddStopTap; // Durak ekle aksiyonu
  final String duration; // Kalan süre (ETA)
  final String type; // İşletme türü (Örn: Benzin İstasyonu, Kafe)
  final String rating; // İşletme puanı
  final String reviewCount; // İşletme yorum sayısı
  final String isOpen; // İşletme açık mı ("Açık" veya "Kapalı")
  final String address; // İşletme adresi

  const PoiBusinessCard({
    super.key,
    required this.title,
    required this.distance,
    this.imageUrl,
    this.onDirectionsTap,
    this.onAddStopTap,
    required this.duration,
    required this.type,
    required this.rating,
    required this.reviewCount,
    required this.isOpen,
    required this.address,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isCurrentlyOpen =
        isOpen.toLowerCase().contains('açık') ||
        isOpen.toLowerCase().contains('open');
    final statusColor = isCurrentlyOpen
        ? Colors.greenAccent.shade400
        : Colors.redAccent.shade400;

    return Container(
      height: 190, // Optimize edilmiş ferah yükseklik
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // --- 1. GÖRSEL ALANI (En Alt Katman) ---
          if (imageUrl != null && imageUrl!.isNotEmpty)
            CachedNetworkImage(
              imageUrl: imageUrl!,
              fit: BoxFit.cover,
              placeholder: (context, url) => _buildPlaceholder(),
              errorWidget: (context, url, error) => _buildPlaceholder(),
            )
          else
            _buildPlaceholder(),

          // --- 2. ÜST HAFİF GRADIENT (Açık görselde okunabilirlik için) ---
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 70,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.25),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // --- 2. SİYAH GRADIENT (Yazıları okutmak için %50'den aşağıya yayılan) ---
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 110,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black87, Colors.black],
                  stops: [0.0, 0.4, 1.0],
                ),
              ),
            ),
          ),

          // --- 3. EN ÜST SATIR (Durum + Süre ve Butonlar) ---
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // SOL ÜST: Durum + Süre ve altına Tür + Mesafe
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: isOpen,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: statusColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                          TextSpan(
                            text: ' • $duration',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$type  •  $distance',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.white70,
                        fontWeight: FontWeight.w400,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),

                // SAĞ ÜST: Aksiyon İkonları
                Row(
                  children: [
                    _GlassIconButton(
                      icon: Icons.add_location_alt_outlined,
                      onTap: onAddStopTap ?? () {},
                    ),
                    const SizedBox(width: 8),
                    _GlassIconButton(
                      icon: Icons.navigation_rounded,
                      onTap: onDirectionsTap ?? () {},
                      isPrimary: true,
                      colorScheme: colorScheme,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // --- 4. EN ALT SATIRLAR (Metin Bilgileri) ---
          Positioned(
            bottom: 12,
            left: 14,
            right: 14,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. SATIR: İşletme Adı ve Puan
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: Colors.white,
                          fontSize: 18, // Başlık dev gibi, net okunsun
                          fontWeight: FontWeight.w400,
                          letterSpacing: -0.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Puan ve Yorum Sayısı (En sağda)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          color: Colors.amber,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          rating,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          ' ($reviewCount)',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: Colors.white70,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 6),

                // 2. SATIR: İşletme Adresi
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_rounded,
                      color: Colors.white60,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        address,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.white60,
                          fontWeight: FontWeight.w300,
                          fontSize: 12,
                        ),
                        maxLines: 1, // Sığmazsa ... koysun
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Resim yoksa çıkacak modern placeholder
  Widget _buildPlaceholder() {
    return Container(
      color: const Color(0xFF1E1E1E), // Daha tok bir arka plan
      child: const Center(
        child: Icon(Icons.image_outlined, color: Colors.white24, size: 48),
      ),
    );
  }
}

// --- SAĞ ÜSTTEKİ MODERN (YARI SAYDAM) İKON BUTONU ---
class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isPrimary;
  final ColorScheme? colorScheme;

  const _GlassIconButton({
    required this.icon,
    required this.onTap,
    this.isPrimary = false,
    this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isPrimary && colorScheme != null
        ? colorScheme!.primary.withValues(alpha: 0.9)
        : Colors.black.withValues(alpha: 0.6);

    return Material(
      color: bgColor,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(8.0), // Buton tıklama alanı
          child: Icon(
            icon,
            size: 20,
            color: Colors.white, // Resmin üstünde daima beyaz görünmeli
          ),
        ),
      ),
    );
  }
}
