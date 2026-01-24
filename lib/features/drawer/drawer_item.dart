import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/theme/text_styles.dart';

class DrawerItem extends StatelessWidget {
  final String title;
  final VoidCallback onTap;
  
  // 🔥 DEĞİŞİKLİK: Sadece resim yolu alıyoruz
  final String iconPath; 

  final bool isDestructive; 
  final Color? iconColor;
  final Color? textColor;
  final Color? backgroundColor;

  const DrawerItem({
    super.key,
    required this.title,
    required this.onTap,
    required this.iconPath, // Artık zorunlu!
    this.isDestructive = false,
    this.iconColor,
    this.textColor,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Renk Ayarları (Çıkış butonu kırmızı, diğerleri tema rengi)
    final effectiveColor = isDestructive 
        ? theme.colorScheme.error 
        : (iconColor ?? theme.colorScheme.onSurfaceVariant);

    final effectiveTextColor = isDestructive
        ? theme.colorScheme.error
        : (textColor ?? theme.colorScheme.onSurface);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onTap: onTap,
        
        // 🔥 ARTIK KONTROL YOK, DİREKT RESİM VAR
        leading: Image.asset(
          iconPath,
          width: 24, // Standart boyut
          height: 24,
          color: effectiveColor, // İkonu yazı rengine boyar (Modern görünüm)
        ),
            
        title: Text(
          title,
          style: AppTextStyles.regular.copyWith( 
            fontSize: 18,
            fontWeight: FontWeight.w400,
            color: effectiveTextColor,
          ),
        ),
        trailing: !isDestructive 
            ? Icon(Icons.chevron_right, size: 18, color: theme.colorScheme.outline) 
            : null,
      ),
    );
  }
}