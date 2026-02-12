import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:moto_comm_app_1/core/widgets/app_button.dart';
import 'package:moto_comm_app_1/core/widgets/app_input_field.dart';
import 'package:moto_comm_app_1/features/auth/presentation/widgets/auth_divider_widget.dart';
import 'package:moto_comm_app_1/features/auth/presentation/widgets/auth_header_widget.dart';
import 'package:moto_comm_app_1/features/auth/presentation/widgets/auth_footer_widget.dart';
import 'package:moto_comm_app_1/features/auth/presentation/widgets/auth_error_widget.dart';
import 'package:provider/provider.dart';
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
      );

      if (success && mounted) {
        context.go('/homepage');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      // Klavye açılınca ekranın yukarı kaymasını engeller (Sabit Kalır)
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        top: false,
        child: CustomScrollView(
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Column(
                children: [
                  // 1. KAVİSLİ HEADER ALANI
                  SizedBox(
                    height: (size.height * 0.35).clamp(240.0, 400.0),
                    child: const AuthHeaderWidget(
                      title: "Tekrar Hoşgeldiniz!",
                      subtitle: "Sürüşe başlamak için giriş yapın.",
                      icon: Icons.two_wheeler,
                    ),
                  ),

                  // 2. FORM VE İÇERİK ALANI
                  Expanded(
                    child: Center(
                      child: Container(
                        // Tablet/Web için max genişlik sınırı (Modern Görünüm)
                        constraints: const BoxConstraints(maxWidth: 450),
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Form(
                          key: _formKey,
                          child: AutofillGroup(
                            // Otomatik doldurma desteği
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const SizedBox(height: 24),

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
                                  label: "E-Posta",
                                  leadingIcon: Icons.email_outlined,
                                  // 🔥 Klavye 'İleri' tuşu çıkar
                                  textInputAction: TextInputAction.next,
                                  validator: (val) =>
                                      (val == null || !val.contains('@'))
                                      ? 'Geçerli bir e-posta girin'
                                      : null,
                                ),

                                const SizedBox(height: 16),

                                // Şifre Alanı
                                AppInputField(
                                  controller: _passwordController,
                                  type: AppInputType.password,
                                  label: "Şifre",
                                  leadingIcon: Icons.lock_outline,
                                  // 🔥 Klavye 'Tamam' tuşu çıkar
                                  textInputAction: TextInputAction.done,
                                  validator: (val) =>
                                      (val == null || val.length < 6)
                                      ? 'En az 6 karakter gerekli'
                                      : null,
                                ),

                                // Beni Hatırla & Şifremi Unuttum
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8.0,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          SizedBox(
                                            height: 24,
                                            width: 24,
                                            child: Checkbox(
                                              value: _rememberMe,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              onChanged: (val) => setState(
                                                () =>
                                                    _rememberMe = val ?? false,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            "Beni Hatırla",
                                            style: theme.textTheme.bodyMedium,
                                          ),
                                        ],
                                      ),
                                      TextButton(
                                        onPressed: () {},
                                        style: TextButton.styleFrom(
                                          padding: EdgeInsets.zero,
                                          minimumSize: const Size(0, 0),
                                          tapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
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
                                ),

                                const SizedBox(height: 24),

                                // Giriş Butonu
                                Consumer<AuthProvider>(
                                  builder: (context, authProvider, _) {
                                    return AppButton(
                                      text: "Giriş Yap",
                                      isLoading: authProvider.isLoading,
                                      size: AppButtonSize.large,
                                      borderRadius: BorderRadius.circular(16),
                                      isFullWidth: true,
                                      onPressed: () =>
                                          _handleLogin(authProvider),
                                    );
                                  },
                                ),

                                const SizedBox(height: 24),

                                // Veya Ayıracı
                                const AuthDividerWidget(),

                                const SizedBox(height: 24),

                                // Google Giriş
                                AppButton(
                                  text: "Google ile devam et",
                                  onPressed: () {},
                                  variant: AppButtonVariant.secondary,
                                  style: AppButtonStyle.outlined,
                                  isFullWidth: true,
                                  icon: Icons.g_mobiledata,
                                  borderRadius: BorderRadius.circular(16),
                                ),

                                const SizedBox(height: 24),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // 3. FOOTER ALANI (Alt kısma sabitlenen link)
                  AuthFooterWidget(
                    questionText: "Hesabınız yok mu?",
                    actionText: "Kayıt Ol",
                    onPressed: () => context.push('/register'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
