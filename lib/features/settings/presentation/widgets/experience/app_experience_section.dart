import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Provider ekle
import 'package:helmove/core/theme/theme_provider.dart'; // ThemeProvider ekle
import 'package:helmove/features/settings/presentation/widgets/structure/helper_widgets.dart';
import 'package:helmove/features/settings/presentation/widgets/structure/settings_section_header.dart';
import 'package:helmove/features/settings/presentation/widgets/structure/settings_tile.dart';
import 'package:helmove/core/theme/app_colors.dart';

class AppExperienceSection extends StatefulWidget {
  const AppExperienceSection({super.key});

  @override
  State<AppExperienceSection> createState() => _AppExperienceSectionState();
}

class _AppExperienceSectionState extends State<AppExperienceSection> {
  bool _notificationsEnabled = true;
  String _currentLanguage = "Türkçe"; // Dil şimdilik yerel kalsın

  @override
  Widget build(BuildContext context) {
    // 🔥 Provider'ı sayfaya çağırıyoruz
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SettingsSectionHeader(title: "Uygulama Deneyimi"),

        // 1. GÖRÜNÜM
        SettingsSelectionTile(
          icon: Icons.dark_mode_outlined,
          title: "Görünüm",
          // Değeri artık Provider'dan alıyor
          currentValue: themeProvider.currentThemeName,
          options: const ["Sistem", "Aydınlık", "Karanlık"],
          onSelect: (val) {
            // Değişikliği Provider'a iletiyor
            themeProvider.setTheme(val);
          },
        ),

        // ... Diğer ayarlar aynı kalacak
        SettingsSelectionTile(
          icon: Icons.language_rounded,
          title: "Dil",
          currentValue: _currentLanguage,
          options: const ["Türkçe", "English", "Deutsch"],
          onSelect: (val) => setState(() => _currentLanguage = val),
        ),

        SettingsTile(
          icon: Icons.notifications_outlined,
          title: "Bildirimler",
          trailing: Switch.adaptive(
            value: _notificationsEnabled,
            activeThumbColor: AppColors.primary,
            onChanged: (val) => setState(() => _notificationsEnabled = val),
          ),
        ),
      ],
    );
  }
}
