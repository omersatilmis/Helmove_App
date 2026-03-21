import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/text_styles.dart';

class AppBuildFrostedButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color glassTint;
  final Color iconColor;
  final Color textColor;
  final double height;
  final double iconSize;
  final double fontSize;
  final VoidCallback onTap;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final double blurSigma;
  final double borderAlpha;
  final double backgroundAlpha;
  final double shadowAlpha;

  const AppBuildFrostedButton({
    super.key,
    required this.title,
    required this.icon,
    required this.glassTint,
    required this.iconColor,
    required this.textColor,
    required this.height,
    required this.iconSize,
    required this.fontSize,
    required this.onTap,
    this.borderRadius = 20,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    this.blurSigma = 10,
    this.borderAlpha = 0.3,
    this.backgroundAlpha = 0.25,
    this.shadowAlpha = 0.05,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          child: Container(
            constraints: BoxConstraints(minHeight: height),
            padding: padding,
            decoration: BoxDecoration(
              color: glassTint.withValues(alpha: backgroundAlpha),
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: glassTint.withValues(alpha: borderAlpha),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: shadowAlpha),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: iconColor, size: iconSize),
                const SizedBox(height: 6),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: fontSize,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
