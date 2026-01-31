import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

// Core Widgets
import 'package:moto_comm_app_1/core/widgets/app_button.dart';
import 'package:moto_comm_app_1/core/widgets/app_input_field.dart';
import 'package:moto_comm_app_1/core/presentation/widgets/professional_error_bottom_sheet.dart';

// Auth Widgets
import 'package:moto_comm_app_1/features/auth/presentation/widgets/auth_header_widget.dart';
import 'package:moto_comm_app_1/features/auth/presentation/widgets/auth_footer_widget.dart';
import 'package:moto_comm_app_1/features/auth/presentation/widgets/auth_divider_widget.dart';

// Providers
import '../providers/auth_provider.dart';
import '../../../profile/presentation/providers/profile_provider.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  final _formKey = GlobalKey<FormState>();
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();

    // Clear profile on entry to ensure clean start
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ProfileProvider>().clearProfile();
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final authProvider = context.read<AuthProvider>();
    if (_formKey.currentState?.validate() ?? false) {
      FocusScope.of(context).unfocus();

      final success = await authProvider.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (!mounted) return;

      // 🔥 FIX: Explicit navigation removed.
      // GoRouter listens to AuthProvider and will redirect to /homepage automatically via 'redirect' logic.
      // context.go('/homepage'); <--- REMOVED

      if (!success && authProvider.errorMessage != null) {
        ProfessionalErrorBottomSheet.show(
          context,
          message: authProvider.errorMessage!,
          title: "Giriş Başarısız",
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      // Klavye açılınca header'ın küçülmesini veya formun kaymasını istemiyoruz.
      resizeToAvoidBottomInset: false,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          top: false, // Header covers status bar
          child: LayoutBuilder(
            builder: (context, constraints) {
              final headerHeight = (constraints.maxHeight * 0.35).clamp(
                280.0,
                360.0,
              );
              return SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Column(
                      children: [
                        // 1. HEADER
                        SizedBox(
                          height: headerHeight,
                          child: const AuthHeaderWidget(
                            title: "Tekrar Hoşgeldiniz!",
                            subtitle: "Sürüşe başlamak için giriş yapın.",
                            icon: Icons.two_wheeler,
                          ),
                        ),

                        // 2. FORM ALANI
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24.0,
                            ),
                            child: Form(
                              key: _formKey,
                              child: AutofillGroup(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    const SizedBox(height: 10),

                                    AppInputField(
                                      controller: _emailController,
                                      type: AppInputType.email,
                                      label: "E-Posta",
                                      leadingIcon: Icons.email_outlined,
                                      textInputAction: TextInputAction.next,
                                      validator: (val) =>
                                          (val == null || !val.contains('@'))
                                          ? 'Geçerli bir e-posta girin'
                                          : null,
                                    ),

                                    const SizedBox(height: 16),

                                    AppInputField(
                                      controller: _passwordController,
                                      type: AppInputType.password,
                                      label: "Şifre",
                                      leadingIcon: Icons.lock_outline,
                                      textInputAction: TextInputAction.done,
                                      onFieldSubmitted: (_) => _handleLogin(),
                                      validator: (val) =>
                                          (val == null || val.length < 6)
                                          ? 'En az 6 karakter gerekli'
                                          : null,
                                    ),

                                    _buildRememberMeRow(theme),

                                    const SizedBox(height: 20),

                                    Consumer<AuthProvider>(
                                      builder: (context, auth, _) => AppButton(
                                        text: "Giriş Yap",
                                        isLoading: auth.isLoading,
                                        size: AppButtonSize.large,
                                        borderRadius: BorderRadius.circular(16),
                                        isFullWidth: true,
                                        onPressed: _handleLogin,
                                      ),
                                    ),

                                    const SizedBox(height: 16),
                                    const AuthDividerWidget(),
                                    const SizedBox(height: 16),

                                    AppButton(
                                      text: "Google ile devam et",
                                      onPressed: () {},
                                      variant: AppButtonVariant.secondary,
                                      style: AppButtonStyle.outlined,
                                      isFullWidth: true,
                                      icon: Icons.g_mobiledata,
                                      borderRadius: BorderRadius.circular(16),
                                    ),

                                    const SizedBox(height: 16),

                                    AppButton(
                                      text: "Apple ile Devam Et",
                                      onPressed: () {},
                                      variant: AppButtonVariant.secondary,
                                      style: AppButtonStyle.outlined,
                                      isFullWidth: true,
                                      icon: Icons.apple,
                                      borderRadius: BorderRadius.circular(16),
                                    ),

                                    //const Spacer(),
                                    AuthFooterWidget(
                                      questionText: "Hesabınız yok mu?",
                                      actionText: "Kayıt Ol",
                                      onPressed: () =>
                                          context.push('/register'),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildRememberMeRow(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              SizedBox(
                height: 24,
                width: 24,
                child: Checkbox(
                  value: _rememberMe,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  onChanged: (val) =>
                      setState(() => _rememberMe = val ?? false),
                ),
              ),
              const SizedBox(width: 8),
              Text("Beni Hatırla", style: theme.textTheme.bodyMedium),
            ],
          ),
          TextButton(
            onPressed: () {},
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(0, 0),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              "Şifremi Unuttum?",
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
