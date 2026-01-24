import 'package:flutter/material.dart';

class AppColors {
  // Bu sınıfın örneklenmesini engelliyoruz
  AppColors._();

  // --- ANA RENKLER (BRAND COLORS) ---
  // 2026 Trendi: "Electric Orange" yerine biraz daha derin, "Burnt Orange" veya "Amber"
  static const Color primary = Color(0xFFFF6F00);      // Ana Turuncu
  static const Color primaryDark = Color(0xFFE65100);  // Koyu Turuncu (Buton basılı hali)
  static const Color primaryLight = Color(0xFFFFD180); // Açık Turuncu (Vurgular)

  // --- LIGHT THEME PALETİ ---
  static const Color lightBackground = Color(0xFFFFFFFF);       // Saf Beyaz
  static const Color lightSurface = Color(0xFFF9F9F9);          // Hafif Kırık Beyaz (Kartlar için)
  static const Color lightSurfaceContainer = Color(0xFFF0F0F0); // Input alanları vb.
  static const Color lightTextPrimary = Color(0xFF1A0604);      // Simsiyah değil, çok koyu gri
  static const Color lightTextSecondary = Color(0xFF757575);    // Yardımcı metinler

  // --- DARK THEME PALETİ (Sıcak Antrasit) ---
  // İçinde çok hafif turuncu/kızıl barındıran koyu gri.
  // Saf siyah (#000000) yerine bu renk gözü daha az yorar ve turuncuyla bütünleşir.
  static const Color darkBackground = Color(0xFF12100E);        // Hafif Turuncu/Kahve tonlu siyah
  static const Color darkSurface = Color(0xFF1C1917);           // Bir tık açığı (Kartlar için)
  static const Color darkSurfaceContainer = Color(0xFF25221F);  // Input alanları
  static const Color darkTextPrimary = Color(0xFFF5F5F5);       // Kırık Beyaz metin
  static const Color darkTextSecondary = Color(0xFFA8A29E);     // Sıcak gri metin

  // --- YARDIMCI RENKLER (SEMANTIC) ---
  static const Color error = Color(0xFFBA1A1A);
  static const Color success = Color(0xFF15803D); // Doğal Yeşil
  static const Color warning = Color(0xFFB45309);
  
  // Sosyal Medya (İhtiyaç olursa)
  static const Color googleRed = Color(0xFFDB4437);
}
