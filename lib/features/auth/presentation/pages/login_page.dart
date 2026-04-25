import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:helmove/core/widgets/app_button.dart';
import 'package:helmove/core/widgets/app_input_field.dart';
import 'package:helmove/features/auth/presentation/widgets/auth_divider_widget.dart';
import 'package:helmove/features/auth/presentation/widgets/auth_header_widget.dart';
import 'package:helmove/features/auth/presentation/widgets/auth_footer_widget.dart';
import 'package:helmove/features/auth/presentation/widgets/auth_error_widget.dart';
import 'package:helmove/features/auth/presentation/widgets/eula_consent_widget.dart';
import 'package:helmove/features/auth/presentation/widgets/eula_webview_bottom_sheet.dart';
import 'package:provider/provider.dart';
import 'package:helmove/l10n/app_localizations.dart';
import '../providers/auth_provider.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _GoogleLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20,
      height: 20,
      child: CustomPaint(painter: _GoogleLogoPainter()),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final center = rect.center;
    final radius = size.width / 2;

    // Kırmızı (sol üst)
    final paint = Paint()..color = const Color(0xFFEA4335);
    canvas.drawArc(rect, -2.36, 1.57, true, paint);

    // Sarı (sol alt)
    paint.color = const Color(0xFFFBBC05);
    canvas.drawArc(rect, -0.79, 1.57, true, paint);

    // Yeşil (sağ alt)
    paint.color = const Color(0xFF34A853);
    canvas.drawArc(rect, 0.79, 1.57, true, paint);

    // Mavi (sağ üst)
    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(rect, 2.36, 1.57, true, paint);

    // Beyaz iç daire
    paint.color = Colors.white;
    canvas.drawCircle(center, radius * 0.6, paint);

    // Mavi sağ çentik (G şekli)
    paint.color = const Color(0xFF4285F4);
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(center.dx, center.dy - radius * 0.25, radius, radius * 0.5),
      Radius.zero,
    );
    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _LoginPageState extends State<LoginPage> {
  // Controller'lar
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;

  // State
  bool _rememberMe = false;
  bool _acceptedEula = false;
  bool _showEulaWarning = false;
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
    if (!_acceptedEula) {
      setState(() => _showEulaWarning = true);
      return;
    }

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

  Future<void> _handleGoogleSignIn(AuthProvider authProvider) async {
    if (!_acceptedEula) {
      setState(() => _showEulaWarning = true);
      return;
    }

    try {
      final googleSignIn = GoogleSignIn(
      serverClientId:
          '636333998568-qj4tp1aaqkc4vjfc1bhh9ls2pmlv544q.apps.googleusercontent.com',
      scopes: ['email', 'profile'],
    );
      final account = await googleSignIn.signIn();
      if (account == null) return;

      final googleAuth = await account.authentication;
      final idToken = googleAuth.idToken;
      if (idToken == null) throw Exception('Google ID token alınamadı');

      final success = await authProvider.socialSignIn(
        provider: 'google',
        idToken: idToken,
        email: account.email,
        displayName: account.displayName,
      );

      if (success && mounted) {
        if (authProvider.wasNewSocialUser) {
          context.go('/complete-profile', extra: {
            'firstName': account.displayName?.split(' ').firstOrNull,
            'lastName': account.displayName?.split(' ').skip(1).join(' '),
          });
        } else {
          context.go('/homepage');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  Future<void> _handleAppleSignIn(AuthProvider authProvider) async {
    if (!_acceptedEula) {
      setState(() => _showEulaWarning = true);
      return;
    }

    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final identityToken = credential.identityToken;
      if (identityToken == null) throw Exception('Apple identity token alınamadı');

      final nameParts = [credential.givenName, credential.familyName]
          .where((s) => s != null && s.isNotEmpty)
          .join(' ');

      final success = await authProvider.socialSignIn(
        provider: 'apple',
        idToken: identityToken,
        email: credential.email,
        displayName: nameParts.isNotEmpty ? nameParts : null,
      );

      if (success && mounted) {
        if (authProvider.wasNewSocialUser) {
          context.go('/complete-profile', extra: {
            'firstName': credential.givenName,
            'lastName': credential.familyName,
          });
        } else {
          context.go('/homepage');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
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
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(
                        horizontal: horizontalPadding,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: constraints.maxWidth > 450
                                ? 450
                                : constraints.maxWidth - (horizontalPadding * 2),
                          ),
                          child: Form(
                            key: _formKey,
                            child: AutofillGroup(
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

                                    EulaConsentWidget(
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

                                    const AuthDividerWidget(),

                                    SizedBox(height: sectionGap),

                                    // Google ile Giriş Butonu
                                    Consumer<AuthProvider>(
                                      builder: (context, authProvider, _) {
                                        return SizedBox(
                                          width: double.infinity,
                                          height: 52,
                                          child: OutlinedButton(
                                            onPressed: authProvider.isLoading
                                                ? null
                                                : () => _handleGoogleSignIn(
                                                    authProvider),
                                            style: OutlinedButton.styleFrom(
                                              side: BorderSide(
                                                color: theme.colorScheme
                                                    .outlineVariant,
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                _GoogleLogo(),
                                                const SizedBox(width: 12),
                                                Text(
                                                  l10n.continueWithGoogle,
                                                  style: theme
                                                      .textTheme.labelLarge
                                                      ?.copyWith(
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),

                                    const SizedBox(height: 12),

                                    // Apple ile Giriş Butonu
                                    Consumer<AuthProvider>(
                                      builder: (context, authProvider, _) {
                                        return SizedBox(
                                          width: double.infinity,
                                          height: 52,
                                          child: OutlinedButton(
                                            onPressed: authProvider.isLoading
                                                ? null
                                                : () => _handleAppleSignIn(
                                                    authProvider),
                                            style: OutlinedButton.styleFrom(
                                              side: BorderSide(
                                                color: theme.colorScheme
                                                    .outlineVariant,
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.apple,
                                                  size: 22,
                                                  color: theme.colorScheme
                                                      .onSurface,
                                                ),
                                                const SizedBox(width: 12),
                                                Text(
                                                  l10n.continueWithApple,
                                                  style: theme
                                                      .textTheme.labelLarge
                                                      ?.copyWith(
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
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

                  // 3. FOOTER ALANI
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
