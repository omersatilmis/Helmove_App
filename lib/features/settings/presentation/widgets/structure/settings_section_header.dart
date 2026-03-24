// Turuncu renkli, küçük puntolu, solunda biraz boşluğu olan bir başlık basmak. "Hesap", "Genel", "Destek" yazıları.


import 'package:flutter/material.dart';
import 'package:helmove/core/theme/app_colors.dart';
import 'package:helmove/core/theme/text_styles.dart';

class SettingsSectionHeader extends StatelessWidget {
  final String title;
  const SettingsSectionHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4, top: 16),
      child: Text(
        title,
        style: AppTextStyles.bodySmall.copyWith(
          fontWeight: FontWeight.bold,
          color: AppColors.primary, // Başlıklar Turuncu
          fontSize: 14,
        ),
      ),
    );
  }
}
