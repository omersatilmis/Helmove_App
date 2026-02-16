import 'dart:ui';
import 'package:flutter/material.dart';

// 🔥 BUZLU CAM BUTONU (MINIMAL VERSİYON)
// Not: Bu butonlar her zaman Header Resmi üzerinde duracağı için
// arka planın siyah transparan ve ikonun beyaz olması her iki tema için de en okunaklısıdır.
class AppButtonFrostedMin extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const AppButtonFrostedMin({
    super.key,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Senin verdiğin kodun birebir aynısı, sadece Widget yapısına oturtuldu.
    return ClipRRect(
      borderRadius: BorderRadius.circular(50),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha:
              0.25,
            ), // Resim üzerinde kontrast için koyu zemin
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(
              icon,
              color: Colors.white,
              size: 22,
            ), // Resim üzerinde beyaz ikon
            onPressed: onTap,
            // IconButton'ın varsayılan padding'ini sıfırlayalım ki 44px içinde tam ortalansın
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ),
      ),
    );
  }
}
