import 'dart:ui'; // ImageFilter için
import 'package:flutter/material.dart';
import '../theme/text_styles.dart';

class GlassInputField extends StatefulWidget {
  final String? label;
  final String hintText;
  final IconData? prefixIcon;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final bool obscureText;
  final TextInputType? keyboardType;

  const GlassInputField({
    super.key,
    this.label,
    required this.hintText,
    this.prefixIcon,
    this.controller,
    this.onChanged,
    this.obscureText = false,
    this.keyboardType,
  });

  @override
  State<GlassInputField> createState() => _GlassInputFieldState();
}

class _GlassInputFieldState extends State<GlassInputField> {
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: AppTextStyles.inputLabel.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
        ],

        // Input Container
        // ClipRRect tüm Stack'i sarmalı ki köşeler hem blur hem container için yuvarlak olsun
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              // KATMAN 1: Sadece Blur Efekti (En altta)
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    color: Colors.transparent, // Blur'un çalışması için gerekli
                  ),
                ),
              ),

              // KATMAN 2: Renk, Border ve TextField (Üstte)
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  // Yarı saydam arka plan rengi
                  color: colorScheme.surfaceContainerLow.withValues(alpha:0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isFocused
                        ? colorScheme.primary
                        : colorScheme.outline.withValues(alpha:0.2),
                    width: _isFocused ? 1.5 : 1,
                  ),
                ),
                child: TextField(
                  controller: widget.controller,
                  onChanged: widget.onChanged,
                  focusNode: _focusNode,
                  obscureText: widget.obscureText,
                  keyboardType: widget.keyboardType,
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: colorScheme.onSurface,
                  ),
                  cursorColor: colorScheme.primary,
                  decoration: InputDecoration(
                    hintText: widget.hintText,
                    filled: false,
                    hintStyle: AppTextStyles.bodyLarge.copyWith(
                      color: colorScheme.onSurfaceVariant.withValues(alpha:0.4),
                    ),
                    prefixIcon: widget.prefixIcon != null
                        ? Icon(
                            widget.prefixIcon,
                            color: _isFocused
                                ? colorScheme.primary
                                : colorScheme.onSurfaceVariant,
                          )
                        : null,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
