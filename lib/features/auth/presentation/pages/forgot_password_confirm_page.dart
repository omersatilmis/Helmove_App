import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:helmove/core/widgets/app_button.dart';
import 'package:helmove/core/widgets/app_input_field.dart';
import 'package:helmove/features/auth/presentation/providers/auth_provider.dart';
import 'package:helmove/features/auth/presentation/widgets/auth_error_widget.dart';
import 'package:helmove/features/auth/presentation/widgets/auth_header_widget.dart';
import 'package:helmove/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

class ForgotPasswordConfirmPage extends StatefulWidget {
  final String token;
  final String? email;

  const ForgotPasswordConfirmPage({super.key, required this.token, this.email});

  @override
  State<ForgotPasswordConfirmPage> createState() =>
      _ForgotPasswordConfirmPageState();
}

class _ForgotPasswordConfirmPageState extends State<ForgotPasswordConfirmPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _newPasswordController;
  late final TextEditingController _confirmPasswordController;

  @override
  void initState() {
    super.initState();
    _newPasswordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
    _newPasswordController.addListener(_clearErrorIfNeeded);
    _confirmPasswordController.addListener(_clearErrorIfNeeded);
  }

  @override
  void dispose() {
    _newPasswordController.removeListener(_clearErrorIfNeeded);
    _confirmPasswordController.removeListener(_clearErrorIfNeeded);
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _clearErrorIfNeeded() {
    final authProvider = context.read<AuthProvider>();
    if (authProvider.errorMessage != null) {
      authProvider.clearError();
    }
  }

  Future<void> _handleConfirmForgotPassword() async {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();
    final authProvider = context.read<AuthProvider>();
    final l10n = AppLocalizations.of(context)!;

    final success = await authProvider.confirmForgotPassword(
      token: widget.token,
      newPassword: _newPasswordController.text,
      confirmNewPassword: _confirmPasswordController.text,
    );
    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.passwordUpdatedMessage),
          backgroundColor: Theme.of(context).colorScheme.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.go('/login');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? l10n.passwordUpdateFailed),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

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
            final isCompactHeight = constraints.maxHeight < 760;
            final horizontalPadding = constraints.maxWidth < 360 ? 16.0 : 24.0;
            final headerHeight = (constraints.maxHeight * 0.26).clamp(
              180.0,
              280.0,
            );
            final sectionGap = isCompactHeight ? 14.0 : 20.0;

            return Column(
              children: [
                SizedBox(
                  height: headerHeight,
                  child: AuthHeaderWidget(
                    title: l10n.updatePasswordButton,
                    subtitle: l10n.passwordStrengthHint,
                  ),
                ),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        12,
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
                              if (widget.email != null &&
                                  widget.email!.trim().isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Text(
                                    widget.email!.trim(),
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
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
                                controller: _newPasswordController,
                                type: AppInputType.newPassword,
                                label: l10n.newPasswordLabel,
                                hint: l10n.newPasswordHint,
                                textInputAction: TextInputAction.next,
                                validator: (value) {
                                  if (value == null || value.length < 6) {
                                    return l10n.passwordTooShort;
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: sectionGap),
                              AppInputField(
                                controller: _confirmPasswordController,
                                type: AppInputType.newPassword,
                                label: l10n.confirmNewPasswordLabel,
                                hint: l10n.confirmNewPasswordHint,
                                textInputAction: TextInputAction.done,
                                onFieldSubmitted: (_) =>
                                    _handleConfirmForgotPassword(),
                                validator: (value) {
                                  if (value != _newPasswordController.text) {
                                    return l10n.passwordsDoNotMatch;
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: sectionGap),
                              Consumer<AuthProvider>(
                                builder: (context, auth, _) {
                                  return AppButton(
                                    text: l10n.updatePasswordButton,
                                    isLoading: auth.isLoading,
                                    size: AppButtonSize.large,
                                    borderRadius: BorderRadius.circular(16),
                                    isFullWidth: true,
                                    onPressed: _handleConfirmForgotPassword,
                                  );
                                },
                              ),
                              SizedBox(height: sectionGap),
                              TextButton.icon(
                                onPressed: () => context.go('/login'),
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
