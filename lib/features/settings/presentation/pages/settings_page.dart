import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:moto_comm_app_1/core/theme/text_styles.dart';

// 🔥 BUTON IMPORT (Core'dan çekiyoruz)
import 'package:moto_comm_app_1/core/widgets/app_button_frosted.dart';

// Parçaları import ediyoruz
import 'package:moto_comm_app_1/features/settings/presentation/widgets/account_section.dart';
import 'package:moto_comm_app_1/features/settings/presentation/widgets/app_experience_section.dart';
import 'package:moto_comm_app_1/features/settings/presentation/widgets/app_settings_section.dart';
import 'package:moto_comm_app_1/features/settings/presentation/widgets/privacy_section.dart';
import 'package:moto_comm_app_1/features/settings/presentation/widgets/support_section.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      // AppBar'ı kaldırdık, yerine aşağıda Custom Header yaptık
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
                  // 👈 SOL: Senin istediğin Frosted Button
                  AppFrostedButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onTap: () => context.pop(),
                  ),

                  // ORTA: Başlık
                  Text(
                    "Ayarlar",
                    style: AppTextStyles.h3.copyWith(
                      color: theme.colorScheme.onSurface,
                      fontSize: 20, // Biraz daha fit dursun
                    ),
                  ),

                  // SAĞ: Dengelemek için boş kutu (Görünmez)
                  // Sol buton 44px olduğu için sağa da 44px boşluk bırakıyoruz ki başlık tam ortalansın.
                  const SizedBox(width: 44),
                ],
              ),
            ),

            // ---------------------------------------------------------
            // 2. AYARLAR İÇERİĞİ (Scroll Edilebilir Alan)
            // ---------------------------------------------------------
            const Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Column(
                  children: [
                    // 🧱 Bloklar
                    AccountSection(),
                    SizedBox(height: 12),

                    AppExperienceSection(),
                    SizedBox(height: 12),

                    AppSettingsSection(),
                    SizedBox(height: 12),

                    PrivacySection(),
                    SizedBox(height: 12),

                    SupportSection(),
                    SizedBox(
                      height: 40,
                    ), // Alt boşluk (Bottom Navigation payı vs.)
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
