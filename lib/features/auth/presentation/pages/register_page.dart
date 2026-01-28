import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:moto_comm_app_1/features/auth/presentation/providers/auth_provider.dart';
import 'package:moto_comm_app_1/features/auth/presentation/widgets/auth_footer_widget.dart';
import 'package:moto_comm_app_1/features/auth/presentation/widgets/auth_header_widget.dart';
import 'register/register_form_widget.dart';
import 'package:moto_comm_app_1/core/presentation/widgets/professional_error_bottom_sheet.dart';

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
    // 1. Validasyon Kontrolü
    if (!_formKey.currentState!.validate()) return;

    // 2. Klavyeyi Kapat
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
            content: const Text("Kayıt başarılı! Giriş yapabilirsiniz."),
            backgroundColor: Theme.of(context).colorScheme.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.pop(); // Login sayfasına dön
      } else if (authProvider.errorMessage != null) {
        ProfessionalErrorBottomSheet.show(
          context,
          message: authProvider.errorMessage!,
          title: "Kayıt Başarısız",
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Remove MediaQuery.of(context) to prevent rebuilds on keyboard open
    // final size = MediaQuery.of(context).size;
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      // 1. HEADER (Dalgalı Tasarım)
                      SizedBox(
                        height: (constraints.maxHeight * 0.25).clamp(
                          220.0,
                          260.0,
                        ),
                        child: const AuthHeaderWidget(
                          title: "Aramıza Katılın",
                          subtitle: "Sürüş deneyiminizi başlatın.",
                        ),
                      ),

                      const Spacer(),

                      // 2. FORM ALANI
                      // Formu ortalamak ve genişliği sınırlamak için container
                      Center(
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 450),
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
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

                      const Spacer(),

                      // 3. FOOTER
                      AuthFooterWidget(
                        questionText: "Zaten hesabınız var mı?",
                        actionText: "Giriş Yap",
                        onPressed: () => context.pop(),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
