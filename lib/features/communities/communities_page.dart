import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_application_1/core/theme/text_styles.dart';

// 🔥 BUTON IMPORT
import 'package:flutter_application_1/core/widgets/app_button_frosted.dart';

class CommunitiesPage extends StatelessWidget {
  const CommunitiesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // ---------------------------------------------------------
            // 1. ÖZEL BAŞLIK ALANI (HEADER)
            // ---------------------------------------------------------
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 👈 SOL: Frosted Button (Size 44)
                  AppFrostedButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onTap: () => context.pop(),
                  ),

                  // ORTA: Başlık
                  Text(
                    "Topluluklar",
                    style: AppTextStyles.h3.copyWith(
                      color: theme.colorScheme.onSurface,
                      fontSize: 20,
                    ),
                  ),

                  // SAĞ: Dengelemek için boşluk (44px)
                  const SizedBox(width: 44), 
                ],
              ),
            ),

            // ---------------------------------------------------------
            // 2. SAYFA İÇERİĞİ
            // ---------------------------------------------------------
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // İkonu "Ayarlar" yerine "Topluluk/Grup" ikonu yaptım
                    Icon(
                      Icons.groups_rounded, 
                      size: 80, 
                      color: theme.colorScheme.primary.withValues(alpha: 0.5)
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Topluluklar Sayfası Hazırlanıyor...",
                      style: AppTextStyles.h3.copyWith(
                        fontSize: 18, 
                        color: theme.colorScheme.onSurface
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}