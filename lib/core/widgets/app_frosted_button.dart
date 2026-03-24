import 'dart:ui';
import 'package:flutter/material.dart';

// --- 1. İKONLU BUZLU CAM BUTONU ---
class AppFrostedButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final double size;
  final double iconSize;

  const AppFrostedButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.size = 44.0, 
    this.iconSize = 24,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        // Blur şiddeti
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Material(
          color: Colors.transparent,
          // Container yerine Ink kullanıyoruz ki dalga efekti (ripple) arkada kalmasın
          child: Ink(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF1E1E1E).withValues(alpha: 0.4)
                  : Colors.white.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.15)
                    : Colors.white.withValues(alpha: 0.5),
                width: 1.5,
              ),
            ),
            // InkWell'i Ink'in içine aldık, böylece tıklama animasyonu camın üstünde görünecek
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(20),
              child: Center( // İkonun tam ortalanmasını garantiye aldık
                child: Icon(
                  icon,
                  color: isDark ? Colors.white : const Color(0xFF1F1F1F),
                  size: iconSize,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// --- 2. YAZILI BUZLU CAM BUTONU ---
class AppFrostedTextButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double height;
  final double borderRadius;
  final Color? backgroundColor;
  final Color? textColor;
  final Color? borderColor;
  final double borderWidth;
  final double? width;
  final double fontSize;
  final EdgeInsetsGeometry? padding;
  final Widget? child;

  const AppFrostedTextButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.height = 52,
    this.borderRadius = 20,
    this.backgroundColor,
    this.textColor,
    this.borderColor,
    this.borderWidth = 1.5,
    this.width,
    this.fontSize = 16,
    this.padding,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final effectiveTextColor =
        textColor ?? (isDark ? Colors.white : Colors.black);
        
    final effectiveBgColor = backgroundColor ??
        (isDark
            ? const Color(0xFF1E1E1E).withValues(alpha: 0.4)
            : Colors.white.withValues(alpha: 0.3));
            
    final effectiveBorderColor = borderColor ??
        (isDark
            ? Colors.white.withValues(alpha: 0.15)
            : Colors.white.withValues(alpha: 0.5));

    final textStyle = TextStyle(
      color: effectiveTextColor,
      fontWeight: FontWeight.w600,
      fontSize: fontSize,
      letterSpacing: 0.5,
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: SizedBox(
          width: width ?? double.infinity,
          height: height,
          child: ElevatedButton(
            onPressed: isLoading ? null : onPressed,
            style: ElevatedButton.styleFrom(
              padding: padding,
              backgroundColor: effectiveBgColor,
              foregroundColor: effectiveTextColor,
              elevation: 0,
              shadowColor: Colors.transparent,
              // Material 3'ün kendi renk atamasını kapatıp cam efektinin saf ve net kalmasını sağladık
              surfaceTintColor: Colors.transparent, 
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(borderRadius),
                side: BorderSide(
                  color: effectiveBorderColor,
                  width: borderWidth,
                ),
              ),
            ),
            child: isLoading
                ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: effectiveTextColor,
                      strokeWidth: 2.5,
                    ),
                  )
                : (child == null
                    ? Text(
                        text,
                        style: textStyle,
                      )
                    : DefaultTextStyle(
                        style: textStyle,
                        child: IconTheme(
                          data: IconThemeData(color: effectiveTextColor),
                          child: child!,
                        ),
                      )),
          ),
        ),
      ),
    );
  }
}
