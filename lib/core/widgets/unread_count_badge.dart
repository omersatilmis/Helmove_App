import 'package:flutter/material.dart';

class UnreadCountBadge extends StatelessWidget {
  final int count;
  final Color backgroundColor;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final Color? borderColor;
  final double? minWidth;
  final double? minHeight;
  final TextStyle? textStyle;

  const UnreadCountBadge({
    super.key,
    required this.count,
    required this.backgroundColor,
    this.margin,
    this.padding,
    this.borderRadius = 10,
    this.borderColor,
    this.minWidth,
    this.minHeight,
    this.textStyle,
  });

  factory UnreadCountBadge.message({
    Key? key,
    required int count,
    required ColorScheme scheme,
  }) {
    return UnreadCountBadge(
      key: key,
      count: count,
      backgroundColor: scheme.primary,
      borderColor: scheme.surface,
      borderRadius: 10,
      minWidth: 20,
      minHeight: 18,
      margin: const EdgeInsets.only(left: 8),
    );
  }

  factory UnreadCountBadge.messageIcon({
    Key? key,
    required int count,
    required ColorScheme scheme,
  }) {
    return UnreadCountBadge(
      key: key,
      count: count,
      backgroundColor: Colors.orange,
      borderColor: scheme.surface,
      borderRadius: 12,
      minWidth: 18,
      minHeight: 18,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
    );
  }

  factory UnreadCountBadge.notificationIcon({
    Key? key,
    required int count,
    required ColorScheme scheme,
  }) {
    return UnreadCountBadge(
      key: key,
      count: count,
      backgroundColor: Colors.red,
      borderColor: scheme.surface,
      borderRadius: 12,
      minWidth: 18,
      minHeight: 18,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayText = count > 99 ? '99+' : count.toString();

    return Container(
      margin: margin,
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      constraints: BoxConstraints(
        minWidth: minWidth ?? 20,
        minHeight: minHeight ?? 18,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: borderColor != null ? Border.all(color: borderColor!, width: 1) : null,
      ),
      child: Text(
        displayText,
        textAlign: TextAlign.center,
        style:
            textStyle ??
            const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              height: 1.1,
            ),
      ),
    );
  }
}

class UnreadDotBadge extends StatelessWidget {
  final Color color;
  final EdgeInsetsGeometry? margin;
  final double size;
  final Color? borderColor;
  final double borderWidth;

  const UnreadDotBadge({
    super.key,
    required this.color,
    this.margin,
    this.size = 8,
    this.borderColor,
    this.borderWidth = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: borderColor != null
            ? Border.all(color: borderColor!, width: borderWidth)
            : null,
      ),
    );
  }
}
