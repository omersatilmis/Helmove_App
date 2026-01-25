import 'package:flutter/material.dart';
import 'package:moto_comm_app_1/core/widgets/app_button.dart';
import 'package:moto_comm_app_1/core/widgets/app_input_field.dart';
import 'package:moto_comm_app_1/features/auth/presentation/providers/auth_provider.dart';
import 'package:moto_comm_app_1/features/auth/presentation/widgets/auth_divider_widget.dart';
import 'package:moto_comm_app_1/features/auth/presentation/widgets/auth_error_widget.dart';

class RegisterFormWidget extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController usernameController;
  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final AuthProvider authProvider;
  final VoidCallback onRegister;

  const RegisterFormWidget({
    super.key,
    required this.formKey,
    required this.usernameController,
    required this.firstNameController,
    required this.lastNameController,
    required this.emailController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.authProvider,
    required this.onRegister,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 450),
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Form(
        key: formKey,
        child: AutofillGroup(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 0),

              // Kullanıcı Adı
              AppInputField(
                controller: usernameController,
                type: AppInputType.standard,
                autofillHints: const [AutofillHints.username],
                size: AppInputSize.medium,
                label: "Kullanıcı Adı",
                leadingIcon: Icons.alternate_email,
                textInputAction: TextInputAction.next,
                validator: (val) => (val == null || val.length < 3)
                    ? 'En az 3 karakter giriniz'
                    : null,
              ),
              const SizedBox(height: 12),

              // Ad ve Soyad (Yan Yana)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: AppInputField(
                      controller: firstNameController,
                      type: AppInputType.firstName,
                      size: AppInputSize.small,
                      leadingIcon: Icons.person_outline,
                      textInputAction: TextInputAction.next,
                      validator: (val) =>
                          (val == null || val.isEmpty) ? 'Gerekli' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppInputField(
                      controller: lastNameController,
                      type: AppInputType.lastName,
                      size: AppInputSize.small,
                      leadingIcon: Icons.person_outline,
                      textInputAction: TextInputAction.next,
                      validator: (val) =>
                          (val == null || val.isEmpty) ? 'Gerekli' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // E-Posta
              AppInputField(
                controller: emailController,
                type: AppInputType.email,
                size: AppInputSize.small,
                leadingIcon: Icons.email_outlined,
                textInputAction: TextInputAction.next,
                validator: (val) => (val == null || !val.contains('@'))
                    ? 'Geçerli bir mail giriniz'
                    : null,
              ),
              const SizedBox(height: 12),

              // Şifre (Yeni Şifre)
              AppInputField(
                controller: passwordController,
                type: AppInputType.newPassword,
                size: AppInputSize.small,
                leadingIcon: Icons.lock_outline,
                textInputAction: TextInputAction.next,
                validator: (val) =>
                    (val == null || val.length < 6) ? 'En az 6 karakter' : null,
              ),
              const SizedBox(height: 12),

              // Şifre Tekrar
              AppInputField(
                controller: confirmPasswordController,
                type: AppInputType.password,
                size: AppInputSize.small,
                label: "Şifre Tekrar",
                leadingIcon: Icons.lock_reset,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => onRegister(),
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Tekrar giriniz';
                  if (val != passwordController.text) {
                    return 'Şifreler uyuşmuyor';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Hata Mesajı Kutusu
              if (authProvider.errorMessage != null)
                AuthErrorWidget(message: authProvider.errorMessage!),

              // Kayıt Ol Butonu
              AppButton(
                text: "Hesap Oluştur",
                isLoading: authProvider.isLoading,
                isFullWidth: true,
                size: AppButtonSize.medium,
                borderRadius: BorderRadius.circular(16),
                onPressed: onRegister,
              ),

              const SizedBox(height: 16),

              // Veya Ayıracı
              const AuthDividerWidget(),
              const SizedBox(height: 16),

              // Google Giriş
              AppButton(
                text: "Google ile devam et",
                onPressed: () {
                  // Google Login Logic
                },
                variant: AppButtonVariant.secondary,
                style: AppButtonStyle.outlined,
                isFullWidth: true,
                icon: Icons.g_mobiledata,
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
