import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // InputFormatter için gerekli

enum AppInputType {
  standard,
  email,
  password,
  newPassword, // Yeni kayıt ekranları için (güçlü şifre önerisi tetikler)
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
  final ValueChanged<String>?
  onFieldSubmitted; // Klavyeden 'Enter'/'Next' yakalamak için
  final List<TextInputFormatter>?
  inputFormatters; // Özel formatlar (örn: sadece sayı)
  final Iterable<String>?
  autofillHints; // Dışarıdan manuel autofill vermek istersen

  final String? Function(String?)? validator;

  final bool enabled;
  final int? minLines; // default 1 if null
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
    this.inputFormatters,
    this.autofillHints,
    this.radius = 12.0,
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
    // password veya newPassword ise gizli başla
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

    return TextFormField(
      controller: widget.controller,
      enabled: widget.enabled,
      validator: widget.validator,

      // --- LOGIC GÜNCELLEMELERİ ---
      autofillHints: _getAutofillHints, // Akıllı autofill
      onFieldSubmitted: widget.onFieldSubmitted, // Klavye aksiyonu
      textInputAction: widget.textInputAction,
      inputFormatters: widget.inputFormatters,

      // -----------------------------
      obscureText: _obscureText,
      keyboardType: _keyboardType,
      textCapitalization: _capitalization,
      minLines: isPassword ? 1 : widget.minLines,
      maxLines: isPassword ? 1 : widget.maxLines,

      style: TextStyle(fontSize: _fontSize, color: theme.colorScheme.onSurface),

      decoration: InputDecoration(
        labelText: widget.label ?? _defaultLabel,
        hintText: widget.hint ?? _defaultHint,
        helperText: widget.helperText,

        // Hata stili
        errorStyle: TextStyle(fontSize: 12, color: theme.colorScheme.error),

        filled: widget.variant == AppInputVariant.filled,
        fillColor: _fillColor(theme),

        contentPadding: _contentPadding,

        prefixIcon:
            widget.prefixWidget ??
            (widget.leadingIcon != null
                ? Icon(
                    widget.leadingIcon,
                    size: 20,
                    color: theme.colorScheme.onSurfaceVariant,
                  )
                : null),

        suffixIcon: widget.suffixWidget ?? _buildSuffixIcon(theme),

        border: _border(theme),
        enabledBorder: _border(theme),
        focusedBorder: _focusedBorder(theme),
        errorBorder: _errorBorder(),
        focusedErrorBorder: _errorBorder(),
        disabledBorder: _disabledBorder(theme),
      ),
    );
  }

  // --- GETTERS & LOGIC ---

  // Otomatik Doldurma İpuçları
  Iterable<String>? get _getAutofillHints {
    if (widget.autofillHints != null) return widget.autofillHints;

    switch (widget.type) {
      case AppInputType.email:
        return const [AutofillHints.email];
      case AppInputType.password:
        return const [AutofillHints.password];
      case AppInputType.newPassword:
        return const [AutofillHints.newPassword]; // Yeni şifre önerisi
      case AppInputType.firstName:
        return const [AutofillHints.givenName];
      case AppInputType.lastName:
        return const [AutofillHints.familyName];
      case AppInputType.phone:
        return const [AutofillHints.telephoneNumber];
      case AppInputType.standard: // Kullanıcı adı genelde standarda düşer
        // Eğer kullanıcı adıysa 'username' dönebilirsin, ama bazen karışır.
        // Şimdilik null bırakıyorum, RegisterPage'de manuel verebilirsin.
        return null;
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
          color: theme.colorScheme.onSurfaceVariant,
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
          color: theme.colorScheme.onSurfaceVariant,
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
        // 'visiblePassword' klavyedeki önerileri (predictive text) kapatır. Güvenlik için şart.
        return TextInputType.visiblePassword;
      case AppInputType.discover:
        return TextInputType.text;
      case AppInputType.url:
        return TextInputType.url;
      case AppInputType.firstName:
      case AppInputType.lastName:
        return TextInputType.name; // İsim klavyesi açar
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

  // --- STYLES ---

  Color _fillColor(ThemeData theme) {
    if (!widget.enabled) {
      return theme.colorScheme.surfaceContainerHighest.withAlpha(128);
    }
    return theme.colorScheme.surfaceContainerLow;
  }

  OutlineInputBorder _border(ThemeData theme) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(widget.radius),
      borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
    );
  }

  OutlineInputBorder _focusedBorder(ThemeData theme) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(widget.radius),
      borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
    );
  }

  OutlineInputBorder _errorBorder() {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(widget.radius),
      borderSide: BorderSide(color: Colors.red.shade600),
    );
  }

  OutlineInputBorder _disabledBorder(ThemeData theme) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: theme.disabledColor.withAlpha(51)),
    );
  }

  double get _fontSize => widget.size == AppInputSize.small
      ? 14
      : 16; // Fontu bir tık büyüttüm (Okunabilirlik)

  EdgeInsets get _contentPadding {
    final double p = widget.size == AppInputSize.small
        ? 14
        : 18; // Paddingleri rahatlattım
    return EdgeInsets.symmetric(horizontal: p, vertical: p);
  }
}
