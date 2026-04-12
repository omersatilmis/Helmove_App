import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:helmove/l10n/app_localizations.dart';

import 'package:helmove/features/auth/presentation/providers/auth_provider.dart';
import 'package:helmove/features/auth/presentation/widgets/auth_footer_widget.dart';
import 'package:helmove/features/auth/presentation/widgets/auth_header_widget.dart';
import 'package:helmove/features/auth/presentation/widgets/eula_consent_widget.dart';
import 'package:helmove/features/auth/presentation/widgets/eula_webview_bottom_sheet.dart';
import 'register/register_form_widget.dart';
import 'package:helmove/core/presentation/widgets/professional_error_bottom_sheet.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  // --- CONTROLLERLAR ---
  late final TextEditingController _usernameController;
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  late final TextEditingController _confirmPasswordController;

  final _formKey = GlobalKey<FormState>();
  bool _acceptedEula = false;
  bool _showEulaWarning = false;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController();
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();

    // UX İyileştirmesi: Kullanıcı yazmaya başladığında eski hata mesajını temizle
    _addClearErrorListeners();
  }

  void _addClearErrorListeners() {
    final controllers = [
      _usernameController,
      _emailController,
      _passwordController,
    ];
    for (var controller in controllers) {
      controller.addListener(() {
        final provider = context.read<AuthProvider>();
        if (provider.errorMessage != null && controller.text.isNotEmpty) {
          provider.clearError();
        }
      });
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Kayıt İşlemi
  Future<void> _handleRegister(AuthProvider authProvider) async {
    if (!_acceptedEula) {
      setState(() => _showEulaWarning = true);
      return;
    }

    // 1. Klavyeyi Kapat
    FocusScope.of(context).unfocus();

    // 3. Kayıt İsteği
    final success = await authProvider.register(
      username: _usernameController.text.trim(),
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      confirmPassword: _confirmPasswordController.text,
    );

    // 4. Başarı Durumu
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.registrationSuccessful),
            backgroundColor: Theme.of(context).colorScheme.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.pop(); // Login sayfasına dön
      } else if (authProvider.errorMessage != null) {
        ProfessionalErrorBottomSheet.show(
          context,
          message: authProvider.errorMessage!,
          title: AppLocalizations.of(context)!.registrationFailed,
        );
      }
    }
  }

  Future<void> _openEula() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      enableDrag: false,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const EulaWebViewBottomSheet(
        url: 'https://helmove.com/terms-of-use',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      resizeToAvoidBottomInset: false,
      body: MediaQuery.removeViewInsets(
        removeBottom: true,
        context: context,
        child: SafeArea(
          top: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isCompactHeight = constraints.maxHeight < 760;
              final horizontalPadding = constraints.maxWidth < 360 ? 16.0 : 24.0;
              final headerHeight = (constraints.maxHeight * 0.20).clamp(
                130.0,
                200.0,
              );
              final formWidth = (constraints.maxWidth - (horizontalPadding * 2))
                  .clamp(220.0, 450.0)
                  .toDouble();

              return Column(
                children: [
                  // 1. HEADER (Dalgalı Tasarım)
                  SizedBox(
                    height: headerHeight,
                    child: AuthHeaderWidget(
                      title: l10n.joinUs,
                      subtitle: l10n.registerSubtitle,
                      verticalOffset: -20.0,
                    ),
                  ),

                  // 2. FORM ALANI
                  Expanded(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: horizontalPadding,
                          vertical: isCompactHeight ? 8 : 12,
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.center,
                          child: SizedBox(
                            width: formWidth,
                            child: RegisterFormWidget(
                              formKey: _formKey,
                              usernameController: _usernameController,
                              firstNameController: _firstNameController,
                              lastNameController: _lastNameController,
                              emailController: _emailController,
                              passwordController: _passwordController,
                              confirmPasswordController:
                                  _confirmPasswordController,
                              authProvider: authProvider,
                              onRegister: () => _handleRegister(authProvider),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  Padding(
                    padding: EdgeInsets.only(
                      left: horizontalPadding,
                      right: horizontalPadding,
                      bottom: isCompactHeight ? 8 : 12,
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 450),
                      child: EulaConsentWidget(
                        value: _acceptedEula,
                        showWarning: _showEulaWarning,
                        onChanged: (value) {
                          setState(() {
                            _acceptedEula = value;
                            if (value) {
                              _showEulaWarning = false;
                            }
                          });
                        },
                        onTapEula: _openEula,
                      ),
                    ),
                  ),

                  // 3. FOOTER
                  AuthFooterWidget(
                    questionText: l10n.alreadyHaveAccount,
                    actionText: l10n.login,
                    onPressed: () => context.pop(),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
