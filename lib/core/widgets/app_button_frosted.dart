import 'dart:ui';
import 'package:flutter/material.dart';

class AppFrostedButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double size;
  final double iconSize;

  const AppFrostedButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.size = 40.0,
    this.iconSize = 24,
  });

  @override
  Widget build(BuildContext context) {
    // Tema kontrolü (Karanlık mı Aydınlık mı?)
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // 🔥 RENK PALETİ AYARLARI

    // Zemin Rengi
    final backgroundColor = isDark
        ? const Color(0x9028140A) // Dark: %50 Siyah (Koyu Buzlu Cam)
        : const Color.fromARGB(
            118,
            160,
            160,
            160,
          ); // Light: %70 Beyaz (Sütlü Buzlu Cam)

    // Çerçeve (Border) Rengi
    final borderColor = isDark
        ? const Color.fromARGB(
            174,
            255,
            255,
            255,
          ) // Dark: %40 Beyaz (Net görünen beyaz çizgi)
        : const Color.fromARGB(
            185,
            24,
            23,
            23,
          ); // Light: %10 Siyah (Kibar gri çizgi)

    // İkon Rengi
    final iconColor = isDark
        ? const Color.fromARGB(126, 91, 88, 84) // Dark: Beyaz İkon
        : const Color(0xFF1F1F1F); // Light: Koyu Gri İkon

    // Köşe Yuvarlaklığı (Senin beğendiğin ayar)
    const double cornerRadius = 14.0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(cornerRadius),
      child: BackdropFilter(
        // Blur şiddeti (10-15 arası idealdir)
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(cornerRadius),
              border: Border.all(
                color: borderColor,
                width: 1.5, // Senin beğendiğin kalınlık
              ),
            ),
            child: Icon(icon, color: iconColor, size: iconSize),
          ),
        ),
      ),
    );
  }
}
