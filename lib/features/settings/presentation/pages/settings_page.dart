import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:helmove/core/di/injection_container.dart';
import 'package:helmove/core/theme/text_styles.dart';

// 🔥 BUTON IMPORT (Core'dan çekiyoruz)
import 'package:helmove/core/widgets/app_frosted_button.dart';

// Parçaları import ediyoruz
import 'package:helmove/features/settings/presentation/widgets/account/account_section.dart';
import 'package:helmove/features/settings/presentation/widgets/experience/app_experience_section.dart';
import 'package:helmove/features/settings/presentation/widgets/app_settings/app_settings_section.dart';
import 'package:helmove/features/settings/presentation/widgets/privacy_location/privacy_section.dart';
import 'package:helmove/features/settings/presentation/widgets/support/support_section.dart';
import '../bloc/settings_bloc.dart';
import '../bloc/settings_state.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<SettingsBloc>(),
      child: const _SettingsView(),
    );
  }
}

class _SettingsView extends StatelessWidget {
  const _SettingsView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocListener<SettingsBloc, SettingsState>(
      listener: (context, state) {
        if (state.status == SettingsStatus.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.successMessage ?? 'İşlem başarılı'),
              backgroundColor: Colors.green,
            ),
          );
        } else if (state.status == SettingsStatus.failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage ?? 'Hata oluştu'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        // AppBar'ı kaldırdık, yerine aşağıda Custom Header yaptık
        body: SafeArea(
          child: Column(
            children: [
              // ---------------------------------------------------------
              // 1. ÖZEL BAŞLIK ALANI (HEADER)
              // ---------------------------------------------------------
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
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
      ),
    );
  }
}
