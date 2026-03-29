import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Provider ekle
import 'package:helmove/core/theme/theme_provider.dart';
import 'package:helmove/core/localization/language_provider.dart'; // LanguageProvider ekle
import 'package:helmove/l10n/app_localizations.dart'; // Localizations ekle
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

  @override
  Widget build(BuildContext context) {
    // 🔥 Provider'ları sayfaya çağırıyoruz
    final themeProvider = Provider.of<ThemeProvider>(context);
    final languageProvider = Provider.of<LanguageProvider>(context);
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsSectionHeader(title: l10n.appExperience),

        // 1. GÖRÜNÜM
        SettingsSelectionTile(
          icon: Icons.dark_mode_outlined,
          title: l10n.appearance,
          // Değeri artık Provider'dan alıyor
          currentValue: themeProvider.currentThemeName,
          options: [l10n.system, l10n.light, l10n.dark],
          onSelect: (val) {
            // Değişikliği Provider'a iletiyor
            themeProvider.setTheme(val);
          },
        ),

        // ... Diğer ayarlar aynı kalacak
        // Dil seçimi artık LanguageProvider'a bağlı
        SettingsSelectionTile(
          icon: Icons.language_rounded,
          title: l10n.language,
          currentValue: languageProvider.currentLanguageName,
          options: const ["Türkçe", "English"],
          onSelect: (val) => languageProvider.setLanguage(val),
        ),

        SettingsTile(
          icon: Icons.notifications_outlined,
          title: l10n.notifications,
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
