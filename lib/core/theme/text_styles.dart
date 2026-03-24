import 'package:flutter/material.dart';
import 'package:helmove/core/theme/app_colors.dart';

class AppTextStyles {
  // Sınıfın örneğinin oluşturulmasını engelliyoruz
  AppTextStyles._();

  static const String fontFamily = 'Urbanist';

  // ---------------------------------------------------------------------------
  // 🔥 BASE STYLES (TEMEL STİLLER - KOLAY KULLANIM İÇİN)
  // ---------------------------------------------------------------------------
  // "Ben sadece fontu ve kalınlığı alayım, gerisini (renk, boyut) kendim yazarım"
  // dediğin durumlar için bunları ekledim. Pubspec haritasına göre ayarlandı.

  static const TextStyle thin = TextStyle(
    fontFamily: fontFamily,
    fontWeight: FontWeight.w100, // 👉 Urbanist-Thin.ttf
  );

  static const TextStyle light = TextStyle(
    fontFamily: fontFamily,
    fontWeight: FontWeight.w300, // 👉 Urbanist-Light.ttf
  );
  
  static const TextStyle regular = TextStyle(
    fontFamily: fontFamily,
    fontWeight: FontWeight.w400, // 👉 Urbanist-Regular.ttf
  );

  static const TextStyle medium = TextStyle(
    fontFamily: fontFamily,
    fontWeight: FontWeight.w500, // 👉 Urbanist-Medium.ttf
  );

  static const TextStyle bold = TextStyle(
    fontFamily: fontFamily,
    fontWeight: FontWeight.w700, // 👉 Urbanist-Bold.ttf
  );

  // ---------------------------------------------------------------------------
  // 📢 BAŞLIKLAR (HEADLINES)
  // ---------------------------------------------------------------------------
  
  // H1: Sayfa Ana Başlıkları (Örn: "Hoşgeldin", "Kayıt Ol")
  static const TextStyle h1 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 32,
    fontWeight: FontWeight.w700, // Bold
    color: AppColors.lightTextPrimary, 
    letterSpacing: -1.0, 
  );

  // H2: Alt Başlıklar, Kart Başlıkları
  static const TextStyle h2 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w700, // Bold
    color: AppColors.lightTextPrimary,
    letterSpacing: -0.5,
  );

  // H3: Küçük Başlıklar, Bölüm İsimleri
  static const TextStyle h3 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w500, // Medium
    color: AppColors.lightTextPrimary,
  );

  // ---------------------------------------------------------------------------
  // 📝 GÖVDE METİNLERİ (BODY)
  // ---------------------------------------------------------------------------

  // Body Large: Okunabilirliği yüksek ana metinler
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400, // Regular
    color: AppColors.lightTextPrimary,
  );

  // Body Medium: Açıklamalar, alt metinler (Gri tonlu)
  static const TextStyle bodyMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400, // Regular
    color: AppColors.lightTextSecondary, 
  );

  // Body Small: Tarih, etiket, küçük detaylar
  static const TextStyle bodySmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w500, // Medium
    color: AppColors.lightTextSecondary,
  );

  // ---------------------------------------------------------------------------
  // 🔘 BUTON ve ÖZEL ALANLAR
  // ---------------------------------------------------------------------------
  
  // Buton içindeki yazılar
  static const TextStyle button = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w700, // Bold
    color: Colors.white,
    letterSpacing: 0.5,
  );

  // Input (TextField) içindeki yazılar
  static const TextStyle inputLabel = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w500, // Medium
    color: AppColors.lightTextSecondary,
  );
}
