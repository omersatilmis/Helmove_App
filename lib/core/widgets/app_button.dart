import 'package:flutter/material.dart';

enum AppButtonVariant {
  primary,
  secondary,
  danger,
}

enum AppButtonStyle {
  filled,
  outlined,
  text,
}

enum AppButtonSize {
  small,
  medium,
  large,
}

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;

  final AppButtonVariant variant;
  final AppButtonStyle style;
  final AppButtonSize size;

  final bool isLoading;
  final bool isFullWidth;
  final double? width;
  final BorderRadius? borderRadius;

  final IconData? icon;
  final bool iconRight;

  const AppButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.style = AppButtonStyle.filled,
    this.size = AppButtonSize.medium,
    this.isLoading = false,
    this.isFullWidth = false,
    this.width,
    this.borderRadius,
    this.icon,
    this.iconRight = false,
  });

@override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Butonun pasif olma durumu (tıklama fonksiyonu yoksa veya yükleniyorsa)
    final bool disabled = onPressed == null || isLoading;

    final Color baseColor = _baseColor(theme);
    final Color textColor = _textColor(theme);

    // DÜZELTME: Opacity en dış katmana alındı.
    return Opacity(
      opacity: disabled ? 0.5 : 1.0, // Pasifken %50 şeffaflaşır
      child: SizedBox(
        width: isFullWidth ? double.infinity : width,
        height: _height,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: disabled ? null : onPressed,
            borderRadius: _radius,
            child: Ink(
              decoration: BoxDecoration(
                color: _backgroundColor(baseColor),
                borderRadius: _radius,
                border: _border(baseColor),
              ),
              child: Center(
                child: isLoading
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(textColor),
                        ),
                      )
                    : _content(textColor),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// ---- CONTENT ----
  Widget _content(Color textColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null && !iconRight) ...[
          Icon(icon, size: _iconSize, color: textColor),
          const SizedBox(width: 8),
        ],
        Text(
          text,
          style: TextStyle(
            fontSize: _fontSize,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        if (icon != null && iconRight) ...[
          const SizedBox(width: 8),
          Icon(icon, size: _iconSize, color: textColor),
        ],
      ],
    );
  }

  /// ---- COLORS ----
  Color _baseColor(ThemeData theme) {
    switch (variant) {
      case AppButtonVariant.primary:
        return theme.colorScheme.primary;
      case AppButtonVariant.secondary:
        return theme.colorScheme.secondary;
      case AppButtonVariant.danger:
        return Colors.red.shade600;
    }
  }

  Color _textColor(ThemeData theme) {
    if (style == AppButtonStyle.filled) {
      return Colors.white;
    }
    return _baseColor(theme);
  }

  Color _backgroundColor(Color baseColor) {
    if (style == AppButtonStyle.filled) {
      return baseColor;
    }
    return Colors.transparent;
  }

  Border? _border(Color baseColor) {
    if (style == AppButtonStyle.outlined) {
      return Border.all(color: baseColor, width: 1.5);
    }
    return null;
  }

  /// ---- SIZES ----
  double get _height {
    switch (size) {
      case AppButtonSize.small:
        return 36;
      case AppButtonSize.medium:
        return 44;
      case AppButtonSize.large:
        return 52;
    }
  }

  double get _fontSize {
    switch (size) {
      case AppButtonSize.small:
        return 13;
      case AppButtonSize.medium:
        return 15;
      case AppButtonSize.large:
        return 16;
    }
  }

  double get _iconSize {
    switch (size) {
      case AppButtonSize.small:
        return 16;
      case AppButtonSize.medium:
        return 18;
      case AppButtonSize.large:
        return 20;
    }
  }

  BorderRadius get _radius =>
      borderRadius ?? BorderRadius.circular(14);
}

