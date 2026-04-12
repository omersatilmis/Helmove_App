import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:helmove/core/widgets/app_button.dart';
import 'package:helmove/core/widgets/app_input_field.dart';
import 'package:helmove/features/auth/presentation/providers/auth_provider.dart';
import 'package:helmove/features/auth/presentation/widgets/auth_error_widget.dart';
import 'package:helmove/features/auth/presentation/widgets/auth_header_widget.dart';
import 'package:helmove/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  late final TextEditingController _emailController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _emailController.addListener(_clearErrorIfNeeded);
  }

  @override
  void dispose() {
    _emailController.removeListener(_clearErrorIfNeeded);
    _emailController.dispose();
    super.dispose();
  }

  void _clearErrorIfNeeded() {
    final authProvider = context.read<AuthProvider>();
    if (_emailController.text.isNotEmpty && authProvider.errorMessage != null) {
      authProvider.clearError();
    }
  }

  Future<void> _handleSendCode() async {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();
    final authProvider = context.read<AuthProvider>();
    final email = _emailController.text.trim();

    final success = await authProvider.forgotPassword(email);
    if (!mounted) return;

    if (success) {
      // E-posta'yı query param olarak taşı — OTP ekranında kullanılacak
      context.push(
        Uri(
          path: '/forgot-password/confirm',
          queryParameters: {'email': email},
        ).toString(),
      );
    }
    // Hata durumunda AuthErrorWidget zaten gösteriyor
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isCompactHeight = constraints.maxHeight < 760;
            final horizontalPadding = constraints.maxWidth < 360 ? 16.0 : 24.0;
            final headerHeight = (constraints.maxHeight * 0.28).clamp(
              180.0,
              300.0,
            );
            final sectionGap = isCompactHeight ? 14.0 : 20.0;

            return Column(
              children: [
                SizedBox(
                  height: headerHeight,
                  child: AuthHeaderWidget(
                    title: l10n.forgotPassword,
                    subtitle:
                        'E-posta adresinizi girin, 6 haneli doğrulama kodunu gönderelim.',
                  ),
                ),
                Expanded(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        8,
                        horizontalPadding,
                        20,
                      ),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 450),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Consumer<AuthProvider>(
                                builder: (context, auth, _) {
                                  if (auth.errorMessage == null) {
                                    return const SizedBox.shrink();
                                  }
                                  return AuthErrorWidget(
                                    message: auth.errorMessage!,
                                  );
                                },
                              ),
                              AppInputField(
                                controller: _emailController,
                                type: AppInputType.email,
                                label: l10n.email,
                                leadingIcon: Icons.email_outlined,
                                textInputAction: TextInputAction.done,
                                validator: (val) =>
                                    (val == null || !val.contains('@'))
                                    ? l10n.invalidEmail
                                    : null,
                                onFieldSubmitted: (_) => _handleSendCode(),
                              ),
                              SizedBox(height: sectionGap),
                              Consumer<AuthProvider>(
                                builder: (context, auth, _) {
                                  return AppButton(
                                    text: 'Kod Gönder',
                                    isLoading: auth.isLoading,
                                    size: AppButtonSize.large,
                                    borderRadius: BorderRadius.circular(16),
                                    isFullWidth: true,
                                    onPressed: _handleSendCode,
                                  );
                                },
                              ),
                              SizedBox(height: sectionGap),
                              TextButton.icon(
                                onPressed: () => Navigator.of(context).pop(),
                                icon: const Icon(
                                  Icons.arrow_back_ios_new,
                                  size: 16,
                                ),
                                label: Text(l10n.back),
                              ),
                            ],
                          ),
                        ),
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
