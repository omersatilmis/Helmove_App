import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:helmove/core/widgets/app_button.dart';
import 'package:helmove/core/widgets/app_input_field.dart';
import 'package:helmove/features/auth/presentation/providers/auth_provider.dart';
import 'package:helmove/features/auth/presentation/widgets/auth_header_widget.dart';
import 'package:helmove/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// OTP + Yeni Şifre Ekranı
// Tek ekranda: 6 haneli OTP girişi + yeni şifre + tekrar + gönder butonu
// ─────────────────────────────────────────────────────────────────────────────

class ForgotPasswordConfirmPage extends StatefulWidget {
  /// ForgotPasswordPage'den gelen e-posta adresi.
  final String email;

  const ForgotPasswordConfirmPage({super.key, required this.email});

  @override
  State<ForgotPasswordConfirmPage> createState() =>
      _ForgotPasswordConfirmPageState();
}

class _ForgotPasswordConfirmPageState extends State<ForgotPasswordConfirmPage> {
  // OTP: 6 ayrı controller + focusNode
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());

  final _formKey = GlobalKey<FormState>();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Inline hata — API'den gelen mesaj
  String? _inlineError;

  // Resend cooldown
  int _resendCooldown = 0;
  Timer? _resendTimer;

  @override
  void initState() {
    super.initState();
    // Başlangıçta 0 — ilk kod az önce gönderildi
    _startResendCooldown();
  }

  @override
  void dispose() {
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final f in _otpFocusNodes) {
      f.dispose();
    }
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  // ── OTP Helpers ────────────────────────────────────────────────────────────

  String get _otpCode =>
      _otpControllers.map((c) => c.text).join();

  bool get _otpComplete => _otpCode.length == 6;

  void _onOtpChanged(int index, String value) {
    setState(() => _inlineError = null);

    if (value.length == 1 && index < 5) {
      // Sonraki kutuya geç
      _otpFocusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      // Backspace → önceki kutuya dön
      _otpFocusNodes[index - 1].requestFocus();
    }

    // Tüm haneler dolduğunda klavyeyi kapat
    if (_otpComplete) {
      _otpFocusNodes[index].unfocus();
    }
  }

  void _clearOtp() {
    for (final c in _otpControllers) {
      c.clear();
    }
    _otpFocusNodes[0].requestFocus();
  }

  // ── Resend Cooldown ────────────────────────────────────────────────────────

  void _startResendCooldown() {
    setState(() => _resendCooldown = 60);
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_resendCooldown > 0) {
          _resendCooldown--;
        } else {
          timer.cancel();
        }
      });
    });
  }

  Future<void> _handleResend() async {
    if (_resendCooldown > 0) return;

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.forgotPassword(widget.email);
    if (!mounted) return;

    if (success) {
      _clearOtp();
      setState(() => _inlineError = null);
      _startResendCooldown();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Yeni kod gönderildi.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
    } else {
      setState(() {
        _inlineError = authProvider.errorMessage ?? 'Kod gönderilemedi.';
      });
    }
  }

  // ── Submit ─────────────────────────────────────────────────────────────────

  Future<void> _handleSubmit() async {
    setState(() => _inlineError = null);

    if (!_otpComplete) {
      setState(() => _inlineError = 'Lütfen 6 haneli kodu eksiksiz girin.');
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();
    final authProvider = context.read<AuthProvider>();

    final success = await authProvider.confirmForgotPassword(
      email: widget.email,
      code: _otpCode,
      newPassword: _newPasswordController.text,
      confirmNewPassword: _confirmPasswordController.text,
    );
    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Şifreniz başarıyla güncellendi.'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.go('/login');
    } else {
      // Geçersiz kod / süresi dolmuş vs. → inline göster + OTP'yi temizle
      setState(() {
        _inlineError =
            authProvider.errorMessage ?? 'Geçersiz veya süresi dolmuş kod.';
      });
      _clearOtp();
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxHeight < 760;
            final hPad = constraints.maxWidth < 360 ? 16.0 : 24.0;
            final headerH = (constraints.maxHeight * 0.22).clamp(160.0, 240.0);
            final gap = isCompact ? 12.0 : 20.0;

            return Column(
              children: [
                SizedBox(
                  height: headerH,
                  child: AuthHeaderWidget(
                    title: 'Şifremi Sıfırla',
                    subtitle: 'E-postanıza gönderilen 6 haneli kodu girin.',
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(hPad, 8, hPad, 24),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 450),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // E-posta göstergesi
                          _EmailBadge(email: widget.email),
                          SizedBox(height: gap),

                          // 10 dakika uyarısı
                          _InfoBanner(
                            icon: Icons.timer_outlined,
                            text: 'Kod 10 dakika geçerlidir.',
                          ),
                          SizedBox(height: gap),

                          // 6 OTP kutusu
                          _OtpRow(
                            controllers: _otpControllers,
                            focusNodes: _otpFocusNodes,
                            onChanged: _onOtpChanged,
                          ),
                          SizedBox(height: gap * 0.5),

                          // Inline hata
                          if (_inlineError != null)
                            _InlineError(message: _inlineError!),

                          SizedBox(height: gap),

                          // Şifre alanları
                          Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                AppInputField(
                                  controller: _newPasswordController,
                                  type: AppInputType.newPassword,
                                  label: l10n.newPasswordLabel,
                                  hint: l10n.newPasswordHint,
                                  textInputAction: TextInputAction.next,
                                  onChanged: (_) =>
                                      setState(() => _inlineError = null),
                                  validator: (v) {
                                    if (v == null || v.length < 6) {
                                      return l10n.passwordTooShort;
                                    }
                                    return null;
                                  },
                                ),
                                SizedBox(height: gap),
                                AppInputField(
                                  controller: _confirmPasswordController,
                                  type: AppInputType.newPassword,
                                  label: l10n.confirmNewPasswordLabel,
                                  hint: l10n.confirmNewPasswordHint,
                                  textInputAction: TextInputAction.done,
                                  onChanged: (_) =>
                                      setState(() => _inlineError = null),
                                  onFieldSubmitted: (_) => _handleSubmit(),
                                  validator: (v) {
                                    if (v != _newPasswordController.text) {
                                      return l10n.passwordsDoNotMatch;
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: gap),

                          // Şifremi Sıfırla butonu
                          Consumer<AuthProvider>(
                            builder: (context, auth, _) {
                              return AppButton(
                                text: 'Şifremi Sıfırla',
                                isLoading: auth.isLoading,
                                size: AppButtonSize.large,
                                borderRadius: BorderRadius.circular(16),
                                isFullWidth: true,
                                onPressed: _handleSubmit,
                              );
                            },
                          ),
                          SizedBox(height: gap * 0.75),

                          // Kodu Tekrar Gönder
                          _ResendButton(
                            cooldown: _resendCooldown,
                            onPressed: _handleResend,
                          ),
                          SizedBox(height: gap * 0.5),

                          // Geri
                          TextButton.icon(
                            onPressed: () => context.pop(),
                            icon: const Icon(Icons.arrow_back_ios_new, size: 16),
                            label: Text(l10n.back),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Alt Widget'lar
// ─────────────────────────────────────────────────────────────────────────────

class _EmailBadge extends StatelessWidget {
  final String email;

  const _EmailBadge({required this.email});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.email_outlined,
            size: 16,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              email,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoBanner({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 15, color: theme.colorScheme.primary),
        const SizedBox(width: 6),
        Text(
          text,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.primary,
          ),
        ),
      ],
    );
  }
}

/// 6 ayrı OTP kutusu — her biri 1 rakam, otomatik odak yönetimi
class _OtpRow extends StatelessWidget {
  final List<TextEditingController> controllers;
  final List<FocusNode> focusNodes;
  final void Function(int index, String value) onChanged;

  const _OtpRow({
    required this.controllers,
    required this.focusNodes,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(
        6,
        (i) => _OtpBox(
          controller: controllers[i],
          focusNode: focusNodes[i],
          onChanged: (v) => onChanged(i, v),
          // Backspace'i yakalamak için RawKeyboardListener yerine
          // onTap'ta focus + KeyboardListener
        ),
      ),
    );
  }
}

class _OtpBox extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;

  const _OtpBox({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: 44,
      height: 52,
      child: KeyboardListener(
        focusNode: FocusNode(skipTraversal: true),
        onKeyEvent: (event) {
          // Backspace basıldığında kutu boşsa onChanged('') ile geri gönder
          if (event is KeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.backspace &&
              controller.text.isEmpty) {
            onChanged('');
          }
        },
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          maxLength: 1,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: onChanged,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: 0,
          ),
          decoration: InputDecoration(
            counterText: '',
            contentPadding: EdgeInsets.zero,
            filled: true,
            fillColor: theme.colorScheme.surfaceContainerHighest,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: theme.colorScheme.outlineVariant,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: theme.colorScheme.primary,
                width: 2,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: theme.colorScheme.outlineVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  final String message;

  const _InlineError({required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            size: 16,
            color: theme.colorScheme.error,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResendButton extends StatelessWidget {
  final int cooldown;
  final VoidCallback onPressed;

  const _ResendButton({required this.cooldown, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final canResend = cooldown == 0;
    final label = canResend
        ? 'Kodu tekrar gönder'
        : 'Kodu tekrar gönder ($cooldown)';

    return TextButton(
      onPressed: canResend ? onPressed : null,
      child: Text(label),
    );
  }
}
