import 'package:flutter/material.dart';

/// ---------------- ENUMS (Aynen korundu) ----------------
enum AppInputType { standard, email, password, firstName, lastName, discover, phone }
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
  
  // YENİ: Validator (Form kontrolü için)
  final String? Function(String?)? validator;

  final bool enabled;
  final int maxLines;
  
  final IconData? leadingIcon;
  final IconData? trailingIcon;
  final VoidCallback? onTrailingTap;

  const AppInputField({
    super.key,
    required this.controller,
    this.type = AppInputType.standard,
    this.variant = AppInputVariant.filled,
    this.size = AppInputSize.medium,
    this.label,
    this.hint,
    this.helperText,
    this.validator, // <-- Validation eklendi
    this.enabled = true,
    this.maxLines = 1,
    this.leadingIcon,
    this.trailingIcon,
    this.onTrailingTap,
  });

  @override
  State<AppInputField> createState() => _AppInputFieldState();
}

class _AppInputFieldState extends State<AppInputField> {
  // Şifre görünürlüğünü yöneten yerel değişken
  bool _obscureText = false;

  @override
  void initState() {
    super.initState();
    // Eğer tip şifre ise, başlangıçta gizli olsun
    _obscureText = widget.type == AppInputType.password;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // TextField yerine TextFormField kullandık
    return TextFormField(
      controller: widget.controller,
      enabled: widget.enabled,
      validator: widget.validator, // Form doğrulama fonksiyonu
      
      obscureText: _obscureText,
      keyboardType: _keyboardType,
      textCapitalization: _capitalization,
      maxLines: widget.type == AppInputType.password ? 1 : widget.maxLines,
      
      style: TextStyle(
        fontSize: _fontSize,
        color: theme.colorScheme.onSurface,
      ),
      
      decoration: InputDecoration(
        labelText: widget.label ?? _defaultLabel,
        hintText: widget.hint ?? _defaultHint,
        helperText: widget.helperText,
        
        filled: widget.variant == AppInputVariant.filled,
        fillColor: _fillColor(theme),
        
        contentPadding: _contentPadding,

        // Sol İkon
        prefixIcon: widget.leadingIcon != null 
            ? Icon(widget.leadingIcon, size: 20, color: theme.colorScheme.onSurfaceVariant) 
            : null,

        // Sağ İkon (Otomatik Şifre Gözü veya Özel İkon)
        suffixIcon: _buildSuffixIcon(theme),
        
        border: _border(theme),
        enabledBorder: _border(theme),
        focusedBorder: _focusedBorder(theme),
        errorBorder: _errorBorder(),
        focusedErrorBorder: _errorBorder(),
        disabledBorder: _disabledBorder(theme),
      ),
    );
  }

  /// ---------------- LOGIC ----------------

  Widget? _buildSuffixIcon(ThemeData theme) {
    // 1. Durum: Şifre alanıysa Göz İkonu koy
    if (widget.type == AppInputType.password) {
      return IconButton(
        icon: Icon(
          _obscureText ? Icons.visibility_outlined : Icons.visibility_off_outlined,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        onPressed: () {
          setState(() {
            _obscureText = !_obscureText;
          });
        },
      );
    }

    // 2. Durum: Dışarıdan özel ikon verildiyse onu koy (Örn: Arama silme X)
    if (widget.trailingIcon != null) {
      return GestureDetector(
        onTap: widget.onTrailingTap,
        child: Icon(widget.trailingIcon, size: 20, color: theme.colorScheme.onSurfaceVariant),
      );
    }

    return null;
  }

  TextInputType get _keyboardType {
    switch (widget.type) {
      case AppInputType.email: return TextInputType.emailAddress;
      case AppInputType.phone: return TextInputType.phone;
      case AppInputType.discover: return TextInputType.text;
      default: return TextInputType.text;
    }
  }

  TextCapitalization get _capitalization {
    switch (widget.type) {
      case AppInputType.firstName:
      case AppInputType.lastName:
        return TextCapitalization.words;
      default:
        return TextCapitalization.none;
    }
  }

  String? get _defaultLabel {
    switch (widget.type) {
      case AppInputType.email: return "Email";
      case AppInputType.password: return "Şifre";
      case AppInputType.firstName: return "Ad";
      case AppInputType.lastName: return "Soyad";
      case AppInputType.phone: return "Telefon";
      case AppInputType.discover: return "Ara";
      default: return widget.label;
    }
  }

  String? get _defaultHint {
    switch (widget.type) {
      case AppInputType.email: return "ornek@mail.com";
      case AppInputType.password: return "••••••••";
      case AppInputType.phone: return "5XX XXX XX XX";
      case AppInputType.discover: return "Kullanıcı veya grup ara...";
      default: return widget.hint;
    }
  }

  /// ---------------- STYLES (Seninkilerle aynı mantıkta) ----------------

  Color _fillColor(ThemeData theme) {
    if (!widget.enabled) return theme.colorScheme.surfaceContainerHighest.withAlpha(128);
    return theme.colorScheme.surfaceContainerLow; // Material 3 Uyumlu
  }

  OutlineInputBorder _border(ThemeData theme) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
    );
  }

  OutlineInputBorder _focusedBorder(ThemeData theme) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
    );
  }

  OutlineInputBorder _errorBorder() {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.red.shade600),
    );
  }
  
  OutlineInputBorder _disabledBorder(ThemeData theme) {
     return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: theme.disabledColor.withAlpha(51)),
    );
  }

  double get _fontSize => widget.size == AppInputSize.small ? 13 : 15;

  EdgeInsets get _contentPadding {
    final double p = widget.size == AppInputSize.small ? 12 : 16;
    return EdgeInsets.symmetric(horizontal: p, vertical: p);
  }
}
