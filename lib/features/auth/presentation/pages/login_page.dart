import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:helmove/core/widgets/app_button.dart';
import 'package:helmove/core/widgets/app_input_field.dart';
import 'package:helmove/features/auth/presentation/widgets/auth_divider_widget.dart';
import 'package:helmove/features/auth/presentation/widgets/auth_header_widget.dart';
import 'package:helmove/features/auth/presentation/widgets/auth_footer_widget.dart';
import 'package:helmove/features/auth/presentation/widgets/auth_error_widget.dart';
import 'package:provider/provider.dart';
import 'package:helmove/l10n/app_localizations.dart';
import '../providers/auth_provider.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // Controller'lar
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;

  // State
  bool _rememberMe = false;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Giriş işlemini tetikleyen fonksiyon
  Future<void> _handleLogin(AuthProvider authProvider) async {
    if (_formKey.currentState!.validate()) {
      // Klavyeyi kapat
      FocusScope.of(context).unfocus();

      final success = await authProvider.login(
        _emailController.text.trim(), // Boşlukları temizle
        _passwordController.text,
        rememberMe: _rememberMe,
      );

      if (success && mounted) {
        context.go('/homepage');
      }
    }
  }

  Future<void> _openForgotPasswordPage() async {
    if (!mounted) return;
    context.push('/forgot-password');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      // Klavye açılınca ekranın yukarı kaymasını engeller (Sabit Kalır)
      resizeToAvoidBottomInset: false,
      body: MediaQuery.removeViewInsets(
        removeBottom: true,
        context: context,
        child: SafeArea(
          top: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isCompactHeight = constraints.maxHeight < 760;
              final horizontalPadding = constraints.maxWidth < 360
                  ? 16.0
                  : 24.0;
              final headerHeight = (constraints.maxHeight * 0.32).clamp(
                200.0,
                360.0,
              );
              final sectionGap = isCompactHeight ? 14.0 : 24.0;

              return Column(
                children: [
                  // 1. KAVİSLİ HEADER ALANI
                  SizedBox(
                    height: headerHeight,
                    child: AuthHeaderWidget(
                      title: l10n.welcomeBack,
                      subtitle: l10n.loginSubtitle,
                      verticalOffset: -1.0,
                    ),
                  ),

                  // 2. FORM VE İÇERİK ALANI
                  Expanded(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: horizontalPadding,
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.center,
                          child: SizedBox(
                            width: constraints.maxWidth > 450
                                ? 450
                                : constraints.maxWidth -
                                      (horizontalPadding * 2),
                            child: Form(
                              key: _formKey,
                              child: AutofillGroup(
                                // Otomatik doldurma desteği
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    SizedBox(height: isCompactHeight ? 8 : 12),

                                    // Hata Mesajı (Varsa Göster)
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

                                    // E-Posta Alanı
                                    AppInputField(
                                      controller: _emailController,
                                      type: AppInputType.email,
                                      label: l10n.email,
                                      leadingIcon: Icons.email_outlined,
                                      // 🔥 Klavye 'İleri' tuşu çıkar
                                      textInputAction: TextInputAction.next,
                                      validator: (val) =>
                                          (val == null || !val.contains('@'))
                                          ? l10n.invalidEmail
                                          : null,
                                    ),

                                    SizedBox(height: isCompactHeight ? 12 : 16),

                                    // Şifre Alanı
                                    AppInputField(
                                      controller: _passwordController,
                                      type: AppInputType.password,
                                      label: l10n.password,
                                      leadingIcon: Icons.lock_outline,
                                      // 🔥 Klavye 'Tamam' tuşu çıkar
                                      textInputAction: TextInputAction.done,
                                      validator: (val) =>
                                          (val == null || val.length < 6)
                                          ? l10n.passwordTooShort
                                          : null,
                                    ),

                                    // Beni Hatırla & Şifremi Unuttum
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 8.0,
                                      ),
                                      child: Wrap(
                                        alignment: WrapAlignment.spaceBetween,
                                        crossAxisAlignment:
                                            WrapCrossAlignment.center,
                                        runSpacing: 4,
                                        spacing: 12,
                                        children: [
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              SizedBox(
                                                height: 24,
                                                width: 24,
                                                child: Checkbox(
                                                  value: _rememberMe,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          4,
                                                        ),
                                                  ),
                                                  onChanged: (val) => setState(
                                                    () => _rememberMe =
                                                        val ?? false,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                l10n.rememberMe,
                                                style:
                                                    theme.textTheme.bodyMedium,
                                              ),
                                            ],
                                          ),
                                          TextButton(
                                            onPressed: _openForgotPasswordPage,
                                            style: TextButton.styleFrom(
                                              padding: EdgeInsets.zero,
                                              minimumSize: const Size(0, 0),
                                              tapTargetSize:
                                                  MaterialTapTargetSize
                                                      .shrinkWrap,
                                            ),
                                            child: Text(
                                              l10n.forgotPassword,
                                              style: TextStyle(
                                                color:
                                                    theme.colorScheme.primary,
                                                fontWeight: FontWeight.w700,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    SizedBox(height: sectionGap),

                                    // Giriş Butonu
                                    Consumer<AuthProvider>(
                                      builder: (context, authProvider, _) {
                                        return AppButton(
                                          text: l10n.login,
                                          isLoading: authProvider.isLoading,
                                          size: AppButtonSize.large,
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          isFullWidth: true,
                                          onPressed: () =>
                                              _handleLogin(authProvider),
                                        );
                                      },
                                    ),

                                    SizedBox(height: sectionGap),

                                    // Veya Ayıracı
                                    const AuthDividerWidget(),

                                    SizedBox(height: sectionGap),

                                    // Google Giriş
                                    AppButton(
                                      text: l10n.continueWithGoogle,
                                      onPressed: () {},
                                      variant: AppButtonVariant.secondary,
                                      style: AppButtonStyle.outlined,
                                      isFullWidth: true,
                                      icon: Icons.g_mobiledata,
                                      borderRadius: BorderRadius.circular(16),
                                    ),

                                    SizedBox(height: isCompactHeight ? 10 : 16),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // 3. FOOTER ALANI (Alt kısma sabitlenen link)
                  AuthFooterWidget(
                    questionText: l10n.dontHaveAccount,
                    actionText: l10n.register,
                    onPressed: () => context.push('/register'),
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
