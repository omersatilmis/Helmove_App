import 'dart:ui'; // ImageFilter için gerekli
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum AppInputType {
  standard,
  email,
  password,
  newPassword,
  firstName,
  lastName,
  discover,
  phone,
  url,
}

enum AppInputVariant { filled, outlined }

enum AppInputSize { small, medium, large }

class AppInputField extends StatefulWidget {
  final TextEditingController controller;
  final AppInputType type;
  final AppInputVariant variant;
  final AppInputSize size;

  final String? label;
  final String? hint;
  final String? helperText;

  final TextInputAction? textInputAction;
  final ValueChanged<String>? onFieldSubmitted;
  final ValueChanged<String>? onChanged;
  final List<TextInputFormatter>? inputFormatters;
  final Iterable<String>? autofillHints;

  final String? Function(String?)? validator;

  final bool enabled;
  final int? minLines;
  final int? maxLines;

  final IconData? leadingIcon;
  final IconData? trailingIcon;
  final VoidCallback? onTrailingTap;
  final double radius;
  final Widget? prefixWidget;
  final Widget? suffixWidget;

  const AppInputField({
    super.key,
    required this.controller,
    this.type = AppInputType.standard,
    this.variant = AppInputVariant.filled,
    this.size = AppInputSize.medium,
    this.label,
    this.hint,
    this.helperText,
    this.validator,
    this.enabled = true,
    this.minLines,
    this.maxLines = 1,
    this.leadingIcon,
    this.trailingIcon,
    this.onTrailingTap,
    this.textInputAction,
    this.onFieldSubmitted,
    this.onChanged,
    this.inputFormatters,
    this.autofillHints,
    this.radius = 12.0, // Dropdown ile uyum için 12 ideal, ama 16 da olur
    this.prefixWidget,
    this.suffixWidget,
  });

  @override
  State<AppInputField> createState() => _AppInputFieldState();
}

class _AppInputFieldState extends State<AppInputField> {
  bool _obscureText = false;

  @override
  void initState() {
    super.initState();
    _obscureText =
        widget.type == AppInputType.password ||
        widget.type == AppInputType.newPassword;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPassword =
        widget.type == AppInputType.password ||
        widget.type == AppInputType.newPassword;

    // 🔥 GLASS EFFECT WRAPPER
    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: TextFormField(
          controller: widget.controller,
          enabled: widget.enabled,
          validator: widget.validator,

          // Logic
          autofillHints: _getAutofillHints,
          onFieldSubmitted: widget.onFieldSubmitted,
          onChanged: widget.onChanged,
          textInputAction: widget.textInputAction,
          inputFormatters: widget.inputFormatters,

          // Text Config
          obscureText: _obscureText,
          keyboardType: _keyboardType,
          textCapitalization: _capitalization,
          minLines: isPassword ? 1 : widget.minLines,
          maxLines: isPassword ? 1 : widget.maxLines,

          // Stil (Yazı Rengi)
          style: TextStyle(
            fontSize: _fontSize,
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w500,
          ),

          cursorColor: theme.colorScheme.primary,

          decoration: InputDecoration(
            labelText: widget.label ?? _defaultLabel,
            hintText: widget.hint ?? _defaultHint,
            helperText: widget.helperText,

            labelStyle: TextStyle(
              color: theme.colorScheme.onSurface.withValues(alpha:0.7),
            ),
            hintStyle: TextStyle(
              color: theme.colorScheme.onSurface.withValues(alpha:0.4),
            ),

            errorStyle: TextStyle(fontSize: 12, color: theme.colorScheme.error),

            // 🔥 GÜNCELLENEN KISIM: Dropdown rengi ile aynı
            filled: true,
            fillColor: _fillColor(theme),

            contentPadding: _contentPadding,

            prefixIcon:
                widget.prefixWidget ??
                (widget.leadingIcon != null
                    ? Icon(
                        widget.leadingIcon,
                        size: 20,
                        color: theme.colorScheme.onSurface.withValues(alpha:0.7),
                      )
                    : null),

            suffixIcon: widget.suffixWidget ?? _buildSuffixIcon(theme),

            // 🔥 BORDER AYARLARI: Dropdown border rengi ile aynı
            border: _border(theme),
            enabledBorder: _border(theme),
            focusedBorder: _focusedBorder(theme),
            errorBorder: _errorBorder(),
            focusedErrorBorder: _errorBorder(),
            disabledBorder: _disabledBorder(theme),
          ),
        ),
      ),
    );
  }

  // --- LOGIC ---

  Iterable<String>? get _getAutofillHints {
    if (widget.autofillHints != null) return widget.autofillHints;
    switch (widget.type) {
      case AppInputType.email:
        return const [AutofillHints.email];
      case AppInputType.password:
        return const [AutofillHints.password];
      case AppInputType.newPassword:
        return const [AutofillHints.newPassword];
      case AppInputType.firstName:
        return const [AutofillHints.givenName];
      case AppInputType.lastName:
        return const [AutofillHints.familyName];
      case AppInputType.phone:
        return const [AutofillHints.telephoneNumber];
      default:
        return null;
    }
  }

  Widget? _buildSuffixIcon(ThemeData theme) {
    if (widget.type == AppInputType.password ||
        widget.type == AppInputType.newPassword) {
      return IconButton(
        icon: Icon(
          _obscureText
              ? Icons.visibility_outlined
              : Icons.visibility_off_outlined,
          color: theme.colorScheme.onSurface.withValues(alpha:0.6),
        ),
        onPressed: () {
          setState(() {
            _obscureText = !_obscureText;
          });
        },
      );
    }
    if (widget.trailingIcon != null) {
      return GestureDetector(
        onTap: widget.onTrailingTap,
        child: Icon(
          widget.trailingIcon,
          size: 20,
          color: theme.colorScheme.onSurface.withValues(alpha:0.6),
        ),
      );
    }
    return null;
  }

  TextInputType get _keyboardType {
    switch (widget.type) {
      case AppInputType.email:
        return TextInputType.emailAddress;
      case AppInputType.phone:
        return TextInputType.phone;
      case AppInputType.password:
      case AppInputType.newPassword:
        return TextInputType.visiblePassword;
      case AppInputType.url:
        return TextInputType.url;
      case AppInputType.firstName:
      case AppInputType.lastName:
        return TextInputType.name;
      default:
        return TextInputType.text;
    }
  }

  TextCapitalization get _capitalization {
    switch (widget.type) {
      case AppInputType.firstName:
      case AppInputType.lastName:
        return TextCapitalization.words;
      case AppInputType.discover:
        return TextCapitalization.sentences;
      default:
        return TextCapitalization.none;
    }
  }

  String? get _defaultLabel {
    switch (widget.type) {
      case AppInputType.email:
        return "E-Posta";
      case AppInputType.password:
        return "Şifre";
      case AppInputType.newPassword:
        return "Yeni Şifre";
      case AppInputType.firstName:
        return "Ad";
      case AppInputType.lastName:
        return "Soyad";
      case AppInputType.phone:
        return "Telefon";
      case AppInputType.discover:
        return "Ara";
      default:
        return widget.label;
    }
  }

  String? get _defaultHint {
    switch (widget.type) {
      case AppInputType.email:
        return "ornek@mail.com";
      case AppInputType.password:
      case AppInputType.newPassword:
        return "••••••••";
      case AppInputType.phone:
        return "5XX XXX XX XX";
      case AppInputType.discover:
        return "Kullanıcı veya grup ara...";
      default:
        return widget.hint;
    }
  }

  // --- STYLES (GÜNCELLENEN KISIMLAR) ---

  // 🔥 Dropdown renginin aynısı
  Color _fillColor(ThemeData theme) {
    if (!widget.enabled) {
      return theme.colorScheme.surfaceContainerLow.withValues(alpha:0.2);
    }
    // Senin beğendiğin renk kodu
    return theme.colorScheme.surfaceContainerLow.withValues(alpha:0.5);
  }

  // 🔥 Border rengi de outline.opacity(0.1) yapıldı
  OutlineInputBorder _border(ThemeData theme) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(widget.radius),
      borderSide: BorderSide(
        color: theme.colorScheme.outline.withValues(alpha:0.1),
        width: 1,
      ),
    );
  }

  OutlineInputBorder _focusedBorder(ThemeData theme) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(widget.radius),
      borderSide: BorderSide(
        color: theme.colorScheme.primary.withValues(alpha:0.8),
        width: 1.5,
      ),
    );
  }

  OutlineInputBorder _errorBorder() {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(widget.radius),
      borderSide: BorderSide(color: Colors.red.shade400, width: 1),
    );
  }

  OutlineInputBorder _disabledBorder(ThemeData theme) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(widget.radius),
      borderSide: BorderSide(
        color: theme.colorScheme.onSurface.withValues(alpha:0.05),
      ),
    );
  }

  double get _fontSize => widget.size == AppInputSize.small ? 14 : 16;

  EdgeInsets get _contentPadding {
    final double p = widget.size == AppInputSize.small ? 14 : 18;
    return EdgeInsets.symmetric(horizontal: p, vertical: p);
  }
}
