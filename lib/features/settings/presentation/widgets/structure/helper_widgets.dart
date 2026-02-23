// expansion, switch, bottom sheet gibi yardımcı widgetlar

import 'package:flutter/material.dart';
import 'package:moto_comm_app_1/core/theme/app_colors.dart';
import 'package:moto_comm_app_1/core/theme/text_styles.dart';

// -----------------------------------------------------------------------------
// 1. GENEL EXPANSION TILE
// -----------------------------------------------------------------------------
class SettingsExpansionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final List<Widget> children;

  const SettingsExpansionTile({
    super.key,
    required this.icon,
    required this.title,
    required this.children,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          shape: const Border(),
          collapsedShape: const Border(),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary, size: 22),
          ),
          title: Text(
            title,
            style: AppTextStyles.medium.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: theme.colorScheme.onSurface,
            ),
          ),
          subtitle: subtitle != null
              ? Text(
                  subtitle!,
                  // Alt başlık rengini temaya göre şeffaflaştırdık
                  style: AppTextStyles.bodySmall.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                )
              : null,
          children: children,
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 2. SEÇİMLİ EXPANSION TILE (Dil, Tema vb.)
// -----------------------------------------------------------------------------
class SettingsSelectionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String currentValue;
  final List<String> options;
  final Function(String) onSelect;

  const SettingsSelectionTile({
    super.key,
    required this.icon,
    required this.title,
    required this.currentValue,
    required this.options,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SettingsExpansionTile(
      icon: icon,
      title: title,
      subtitle: currentValue,
      children: options.map((option) {
        final isSelected = option == currentValue;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.05)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            dense: true,
            title: Text(
              option,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                // Seçiliyse Turuncu, değilse Temanın Yazı Rengi
                color: isSelected
                    ? AppColors.primary
                    : theme.colorScheme.onSurface,
                fontSize: 14,
              ),
            ),
            trailing: isSelected
                ? const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.primary,
                    size: 20,
                  )
                : null,
            onTap: () => onSelect(option),
          ),
        );
      }).toList(),
    );
  }
}

// -----------------------------------------------------------------------------
// 3. SWITCH TILE
// -----------------------------------------------------------------------------
class SettingsSwitchTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final Function(bool) onChanged;

  const SettingsSwitchTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SwitchListTile.adaptive(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      activeThumbColor: AppColors.primary,
      title: Text(
        title,
        style: AppTextStyles.medium.copyWith(
          color: theme.colorScheme.onSurface,
          fontSize: 14,
        ),
      ),
      subtitle: Text(
        subtitle,
        // Alt başlık rengini temaya göre ayarladık
        style: AppTextStyles.bodySmall.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
        ),
      ),
      value: value,
      onChanged: onChanged,
    );
  }
}

// -----------------------------------------------------------------------------
// 4. ACTION TILE
// -----------------------------------------------------------------------------
class SettingsActionTile extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  const SettingsActionTile({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final secondaryColor = theme.colorScheme.onSurface.withValues(alpha: 0.5);

    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
      // İkon rengini temaya bağladık
      leading: Icon(icon, size: 20, color: secondaryColor),
      title: Text(
        title,
        style: AppTextStyles.medium.copyWith(
          color: theme.colorScheme.onSurface,
          fontSize: 14,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: AppTextStyles.medium.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          Icon(Icons.chevron_right_rounded, size: 18, color: secondaryColor),
        ],
      ),
      onTap: onTap,
    );
  }
}

// -----------------------------------------------------------------------------
// 5. BOTTOM SHEET AÇICI
// -----------------------------------------------------------------------------
void showSettingsBottomSheet(
  BuildContext context,
  String title,
  List<String> options,
  Function(String) onSelect,
) {
  final theme = Theme.of(context);

  showModalBottomSheet(
    context: context,
    // Arka plan rengini scaffold rengine eşitledik (Dark mode için kritik)
    backgroundColor: theme.scaffoldBackgroundColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            // Tutamaç rengini tema divider rengine bağladık
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                title,
                // Başlık rengi dinamik oldu
                style: AppTextStyles.h3.copyWith(
                  fontSize: 18,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            ...options.map(
              (option) => ListTile(
                title: Text(
                  option,
                  // Seçenek rengi dinamik oldu
                  style: AppTextStyles.medium.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                onTap: () {
                  onSelect(option);
                  Navigator.pop(context);
                },
                trailing: Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      );
    },
  );
}
