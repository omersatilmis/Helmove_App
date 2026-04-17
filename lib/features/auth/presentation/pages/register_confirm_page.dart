import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:helmove/core/widgets/app_button.dart';
import 'package:helmove/features/auth/presentation/providers/auth_provider.dart';
import 'package:helmove/features/auth/presentation/widgets/auth_header_widget.dart';
import 'package:provider/provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Kayıt OTP Doğrulama Ekranı
// send-register-otp başarılı olunca buraya geliniyor.
// Kullanıcı 6 haneli kodu girer → confirm-register çağrılır → login'e yönlendirilir.
// ─────────────────────────────────────────────────────────────────────────────

class RegisterConfirmPage extends StatefulWidget {
  final String email;
  final String username;
  final String firstName;
  final String lastName;
  final String password;
  final String confirmPassword;

  const RegisterConfirmPage({
    super.key,
    required this.email,
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.password,
    required this.confirmPassword,
  });

  @override
  State<RegisterConfirmPage> createState() => _RegisterConfirmPageState();
}

class _RegisterConfirmPageState extends State<RegisterConfirmPage> {
  final List<TextEditingController> _otpControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes =
      List.generate(6, (_) => FocusNode());

  String? _inlineError;

  // 10 dakika (600 saniye) geri sayım
  int _secondsLeft = 600;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final f in _otpFocusNodes) {
      f.dispose();
    }
    _countdownTimer?.cancel();
    super.dispose();
  }

  // ── OTP Helpers ────────────────────────────────────────────────────────────

  String get _otpCode => _otpControllers.map((c) => c.text).join();

  bool get _otpComplete => _otpCode.length == 6;

  void _onOtpChanged(int index, String value) {
    setState(() => _inlineError = null);

    if (value.length == 1 && index < 5) {
      _otpFocusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _otpFocusNodes[index - 1].requestFocus();
    }

    // 6. hane dolunca otomatik gönder
    if (_otpComplete) {
      _otpFocusNodes[index].unfocus();
      _handleSubmit();
    }
  }

  void _clearOtp() {
    for (final c in _otpControllers) {
      c.clear();
    }
    _otpFocusNodes[0].requestFocus();
  }

  // ── Countdown ──────────────────────────────────────────────────────────────

  void _startCountdown() {
    setState(() => _secondsLeft = 600);
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_secondsLeft > 0) {
          _secondsLeft--;
        } else {
          timer.cancel();
        }
      });
    });
  }

  String get _timerLabel {
    final m = _secondsLeft ~/ 60;
    final s = _secondsLeft % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  // ── Resend ─────────────────────────────────────────────────────────────────

  Future<void> _handleResend() async {
    if (_secondsLeft > 0) return;

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.sendRegisterOtp(
      username: widget.username,
      firstName: widget.firstName,
      lastName: widget.lastName,
      email: widget.email,
      password: widget.password,
      confirmPassword: widget.confirmPassword,
    );
    if (!mounted) return;

    if (success) {
      _clearOtp();
      setState(() => _inlineError = null);
      _startCountdown();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Yeni doğrulama kodu gönderildi.'),
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
    if (!_otpComplete) {
      setState(() => _inlineError = 'Lütfen 6 haneli kodu eksiksiz girin.');
      return;
    }

    setState(() => _inlineError = null);
    FocusScope.of(context).unfocus();

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.confirmRegister(
      email: widget.email,
      code: _otpCode,
    );
    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Hesabınız oluşturuldu! Giriş yapabilirsiniz.'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.go('/login');
    } else {
      final error = authProvider.errorMessage ?? 'Doğrulama başarısız.';
      setState(() => _inlineError = error);

      // Kod süresi dolmuşsa OTP'yi temizleme — kullanıcı yeni kod isteyebilir
      // Geçersiz kod ise OTP'yi temizle
      final isExpired = error.toLowerCase().contains('süre') ||
          error.toLowerCase().contains('expir');
      if (!isExpired) {
        _clearOtp();
      }
    }
  }

  // ── Email Maskeleme ────────────────────────────────────────────────────────

  String _maskEmail(String email) {
    final parts = email.split('@');
    if (parts.length != 2) return email;
    final local = parts[0];
    final domain = parts[1];
    if (local.length <= 2) return email;
    return '${local.substring(0, 2)}***@$domain';
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maskedEmail = _maskEmail(widget.email);
    final timerExpired = _secondsLeft == 0;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxHeight < 760;
            final hPad = constraints.maxWidth < 360 ? 16.0 : 24.0;
            final headerH =
                (constraints.maxHeight * 0.22).clamp(160.0, 240.0);
            final gap = isCompact ? 12.0 : 20.0;

            return Column(
              children: [
                SizedBox(
                  height: headerH,
                  child: AuthHeaderWidget(
                    title: 'E-posta Doğrulama',
                    subtitle: 'Mailinize gönderilen 6 haneli kodu girin.',
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
                          // E-posta göstergesi (maskeli)
                          _EmailBadge(email: maskedEmail),
                          SizedBox(height: gap),

                          // Geri sayım timer
                          _CountdownBanner(
                            timerLabel: _timerLabel,
                            expired: timerExpired,
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

                          // Doğrula butonu
                          Consumer<AuthProvider>(
                            builder: (context, auth, _) {
                              return AppButton(
                                text: 'Doğrula',
                                isLoading: auth.isLoading,
                                size: AppButtonSize.large,
                                borderRadius: BorderRadius.circular(16),
                                isFullWidth: true,
                                onPressed: _handleSubmit,
                              );
                            },
                          ),
                          SizedBox(height: gap * 0.75),

                          // Yeni Kod İste (timer dolunca aktif)
                          _ResendButton(
                            expired: timerExpired,
                            onPressed: _handleResend,
                          ),
                          SizedBox(height: gap * 0.5),

                          // Geri
                          TextButton.icon(
                            onPressed: () => context.pop(),
                            icon: const Icon(
                                Icons.arrow_back_ios_new, size: 16),
                            label: const Text('Geri'),
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
          Icon(Icons.email_outlined,
              size: 16, color: theme.colorScheme.onSurfaceVariant),
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

class _CountdownBanner extends StatelessWidget {
  final String timerLabel;
  final bool expired;

  const _CountdownBanner({required this.timerLabel, required this.expired});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color =
        expired ? theme.colorScheme.error : theme.colorScheme.primary;
    final text = expired
        ? 'Kodun süresi doldu. Yeni kod isteyin.'
        : 'Kod $timerLabel içinde geçerliliğini yitirecek.';

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(expired ? Icons.timer_off_outlined : Icons.timer_outlined,
            size: 15, color: color),
        const SizedBox(width: 6),
        Text(
          text,
          style: theme.textTheme.bodySmall?.copyWith(color: color),
        ),
      ],
    );
  }
}

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
              borderSide:
                  BorderSide(color: theme.colorScheme.outlineVariant),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                  color: theme.colorScheme.primary, width: 2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: theme.colorScheme.outlineVariant),
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
          Icon(Icons.error_outline, size: 16, color: theme.colorScheme.error),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResendButton extends StatelessWidget {
  final bool expired;
  final VoidCallback onPressed;

  const _ResendButton({required this.expired, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: expired ? onPressed : null,
      child: Text(
        expired ? 'Yeni Kod İste' : 'Yeni Kod İste (süre dolunca aktif olur)',
      ),
    );
  }
}
