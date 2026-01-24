// Soluna ikon koyar, ortasına yazı yazar, sağına ok işareti (>) koyar.


import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/theme/app_colors.dart';
import 'package:flutter_application_1/core/theme/text_styles.dart';

class SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing; // Switch veya özel yazı koymak için
  final Color? iconColor;
  final bool isDestructive; // Çıkış yap butonu için

  const SettingsTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.trailing,
    this.iconColor,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Yıkıcı (Destructive) ise Kırmızı, değilse varsayılan renkler
    final effectiveIconColor = isDestructive ? AppColors.error : (iconColor ?? AppColors.primary);
    final effectiveTextColor = isDestructive ? AppColors.error : theme.colorScheme.onSurface;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow, // Hafif gri/koyu zemin
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        
        // Sol İkon (Yuvarlak kutu içinde)
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: effectiveIconColor.withValues(alpha: 0.1), // Hafif transparan zemin
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: effectiveIconColor, size: 22),
        ),

        // Başlık
        title: Text(
          title,
          style: AppTextStyles.medium.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: effectiveTextColor,
          ),
        ),

        // Alt Başlık (Varsa)
        subtitle: subtitle != null 
          ? Text(
              subtitle!,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.lightTextSecondary),
            ) 
          : null,

        // Sağ Taraf (Ok işareti veya Switch)
        trailing: trailing ?? Icon(
          Icons.chevron_right_rounded, 
          color: AppColors.lightTextSecondary,
        ),
      ),
    );
  }
}