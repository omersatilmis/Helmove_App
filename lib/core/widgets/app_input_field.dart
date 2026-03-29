import 'dart:ui';
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
  final FocusNode? focusNode;

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
  final bool showFocusBorder;
  final double? verticalPadding;

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
    this.focusNode,
    this.radius = 16.0,
    this.prefixWidget,
    this.suffixWidget,
    this.showFocusBorder = true,
    this.verticalPadding,
  });

  @override
  State<AppInputField> createState() => _AppInputFieldState();
}

class _AppInputFieldState extends State<AppInputField>
    with SingleTickerProviderStateMixin {
  bool _obscureText = false;
  late FocusNode _focusNode;
  bool _isFocused = false;
  late AnimationController _animController;
  late Animation<double> _glowAnimation;
  final GlobalKey<FormFieldState<String>> _fieldKey =
      GlobalKey<FormFieldState<String>>();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
    _obscureText =
        widget.type == AppInputType.password ||
        widget.type == AppInputType.newPassword;

    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_handleFocusChange);

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _glowAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
  }

  void _onControllerChanged() {
    if (_fieldKey.currentState != null &&
        widget.controller.text != _fieldKey.currentState!.value) {
      _fieldKey.currentState!.didChange(widget.controller.text);
    }
  }

  void _handleFocusChange() {
    if (!mounted) return;
    setState(() => _isFocused = _focusNode.hasFocus);
    if (_focusNode.hasFocus) {
      _animController.forward();
    } else {
      _animController.reverse();
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    _animController.dispose();
    if (widget.focusNode == null) {
      _focusNode.dispose();
    } else {
      _focusNode.removeListener(_handleFocusChange);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final isPassword =
        widget.type == AppInputType.password ||
        widget.type == AppInputType.newPassword;
    final isMultiline =
        (widget.maxLines ?? 1) > 1 || (widget.minLines ?? 1) > 1;
    final effectiveKeyboardType =
        (isMultiline &&
                widget.textInputAction == TextInputAction.newline &&
                _keyboardType == TextInputType.text)
            ? TextInputType.multiline
            : _keyboardType;

    final label = widget.label ?? _defaultLabel;

    return FormField<String>(
      key: _fieldKey,
      initialValue: widget.controller.text,
      validator: widget.validator,
      builder: (FormFieldState<String> fieldState) {
        final hasError = fieldState.hasError;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── LABEL ──
            if (label != null) ...[
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 6),
                child: Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Urbanist',
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: _isFocused
                        ? cs.primary
                        : cs.onSurface.withValues(alpha: 0.55),
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],

            // ── INPUT CONTAINER ──
            AnimatedBuilder(
              animation: _glowAnimation,
              builder: (context, child) {
                final glowValue = _glowAnimation.value;
                return Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(widget.radius),
                    // Subtle outer glow on focus
                    boxShadow: widget.showFocusBorder
                        ? [
                            BoxShadow(
                              color: cs.primary.withValues(
                                alpha: 0.12 * glowValue,
                              ),
                              blurRadius: 12 * glowValue,
                              spreadRadius: 1 * glowValue,
                            ),
                          ]
                        : null,
                  ),
                  child: child,
                );
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(widget.radius),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    decoration: BoxDecoration(
                      color: isDark
                          ? cs.surfaceContainerLow.withValues(
                              alpha: _isFocused ? 0.6 : 0.45,
                            )
                          : cs.surfaceContainerLow.withValues(
                              alpha: _isFocused ? 0.8 : 0.5,
                            ),
                      borderRadius: BorderRadius.circular(widget.radius),
                      border: Border.all(
                        color: hasError
                            ? cs.error.withValues(alpha: 0.8)
                            : (_isFocused && widget.showFocusBorder
                                  ? cs.primary.withValues(alpha: 0.6)
                                  : cs.outline.withValues(
                                      alpha: isDark ? 0.08 : 0.12,
                                    )),
                        width: _isFocused || hasError ? 1.5 : 1,
                      ),
                    ),
                    child: TextField(
                      controller: widget.controller,
                      focusNode: _focusNode,
                      enabled: widget.enabled,
                      autofillHints: _getAutofillHints,
                      onSubmitted: widget.onFieldSubmitted,
                      onChanged: (val) {
                        fieldState.didChange(val);
                        if (widget.onChanged != null) widget.onChanged!(val);
                      },
                      textInputAction: widget.textInputAction,
                      inputFormatters: widget.inputFormatters,
                      obscureText: _obscureText,
                      keyboardType: effectiveKeyboardType,
                      textCapitalization: _capitalization,
                      minLines: isPassword ? 1 : widget.minLines,
                      maxLines: isPassword ? 1 : widget.maxLines,
                      style: TextStyle(
                        fontFamily: 'Urbanist',
                        fontSize: _fontSize,
                        color: cs.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                      cursorColor: cs.primary,
                      cursorWidth: 1.8,
                      cursorRadius: const Radius.circular(2),
                      decoration: InputDecoration(
                        hintText: widget.hint ?? _defaultHint,
                        helperText: widget.helperText,
                        hintStyle: TextStyle(
                          fontFamily: 'Urbanist',
                          color: cs.onSurface.withValues(alpha: 0.3),
                          fontSize: _fontSize,
                          fontWeight: FontWeight.w400,
                        ),
                        filled: false,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        focusedErrorBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                        contentPadding: _contentPadding,
                        prefixIcon:
                            widget.prefixWidget ??
                            (widget.leadingIcon != null
                                ? Padding(
                                    padding: const EdgeInsets.only(
                                      left: 14,
                                      right: 8,
                                    ),
                                    child: Icon(
                                      widget.leadingIcon,
                                      size: 20,
                                      color: _isFocused
                                          ? cs.primary.withValues(alpha: 0.8)
                                          : cs.onSurface.withValues(alpha: 0.4),
                                    ),
                                  )
                                : null),
                        prefixIconConstraints: widget.leadingIcon != null
                            ? const BoxConstraints(minWidth: 42, minHeight: 0)
                            : null,
                        suffixIcon: widget.suffixWidget ?? _buildSuffixIcon(cs),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ── ERROR TEXT ──
            if (hasError)
              Padding(
                padding: const EdgeInsets.only(top: 8, left: 4),
                child: Text(
                  fieldState.errorText!,
                  style: TextStyle(
                    fontFamily: 'Urbanist',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: cs.error.withValues(alpha: 0.9),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // LOGIC
  // ═══════════════════════════════════════════════════════════════════════════

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

  Widget? _buildSuffixIcon(ColorScheme cs) {
    if (widget.type == AppInputType.password ||
        widget.type == AppInputType.newPassword) {
      return Padding(
        padding: const EdgeInsets.only(right: 4),
        child: IconButton(
          icon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Icon(
              _obscureText
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              key: ValueKey(_obscureText),
              size: 20,
              color: cs.onSurface.withValues(alpha: 0.45),
            ),
          ),
          onPressed: () => setState(() => _obscureText = !_obscureText),
          splashRadius: 20,
        ),
      );
    }
    if (widget.trailingIcon != null) {
      return Padding(
        padding: const EdgeInsets.only(right: 12),
        child: GestureDetector(
          onTap: widget.onTrailingTap,
          child: Icon(
            widget.trailingIcon,
            size: 20,
            color: cs.onSurface.withValues(alpha: 0.45),
          ),
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
        return null; // Discover alanında label yok, sadece hint
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

  // ═══════════════════════════════════════════════════════════════════════════
  // STYLES
  // ═══════════════════════════════════════════════════════════════════════════

  double get _fontSize {
    switch (widget.size) {
      case AppInputSize.small:
        return 14;
      case AppInputSize.large:
        return 17;
      default:
        return 15;
    }
  }

  EdgeInsets get _contentPadding {
    final double ph = widget.leadingIcon != null
        ? 0
        : (widget.size == AppInputSize.small ? 14 : 16);
    final double pv =
        widget.verticalPadding ?? (widget.size == AppInputSize.small ? 12 : 16);
    return EdgeInsets.fromLTRB(ph, pv, 16, pv);
  }
}
