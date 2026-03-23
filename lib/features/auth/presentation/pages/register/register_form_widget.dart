import 'package:flutter/material.dart';
import 'package:moto_comm_app_1/core/widgets/app_button.dart';
import 'package:moto_comm_app_1/core/widgets/app_input_field.dart';
import 'package:moto_comm_app_1/features/auth/presentation/providers/auth_provider.dart';
import 'package:moto_comm_app_1/features/auth/presentation/widgets/auth_divider_widget.dart';

class RegisterFormWidget extends StatefulWidget {
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
  State<RegisterFormWidget> createState() => _RegisterFormWidgetState();
}

class _RegisterFormWidgetState extends State<RegisterFormWidget> {
  int _currentStep = 0;

  final _step1Key = GlobalKey<FormState>();
  final _step2Key = GlobalKey<FormState>();
  final _step3Key = GlobalKey<FormState>();

  void _nextStep() {
    FocusScope.of(context).unfocus();
    bool isValid = false;
    if (_currentStep == 0) {
      isValid = _step1Key.currentState?.validate() ?? false;
    } else if (_currentStep == 1) {
      isValid = _step2Key.currentState?.validate() ?? false;
    }

    if (isValid) {
      setState(() => _currentStep++);
    }
  }

  void _prevStep() {
    FocusScope.of(context).unfocus();
    setState(() => _currentStep--);
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    if (_step3Key.currentState?.validate() ?? false) {
      widget.onRegister();
    }
  }

  Widget _buildStep1() {
    return Form(
      key: _step1Key,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppInputField(
            controller: widget.usernameController,
            type: AppInputType.standard,
            autofillHints: const [AutofillHints.username],
            label: "Kullanıcı Adı",
            leadingIcon: Icons.alternate_email,
            textInputAction: TextInputAction.next,
            validator: (val) => (val == null || val.length < 3)
                ? 'En az 3 karakter giriniz'
                : null,
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: AppInputField(
                  controller: widget.firstNameController,
                  type: AppInputType.firstName,
                  label: "Ad",
                  leadingIcon: Icons.person_outline,
                  textInputAction: TextInputAction.next,
                  validator: (val) =>
                      (val == null || val.trim().isEmpty) ? 'Gerekli' : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppInputField(
                  controller: widget.lastNameController,
                  type: AppInputType.lastName,
                  label: "Soyad",
                  leadingIcon: Icons.person_outline,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _nextStep(),
                  validator: (val) =>
                      (val == null || val.trim().isEmpty) ? 'Gerekli' : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStep2() {
    return Form(
      key: _step2Key,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppInputField(
            controller: widget.emailController,
            type: AppInputType.email,
            label: "E-Posta Adresi",
            leadingIcon: Icons.email_outlined,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _nextStep(),
            validator: (val) => (val == null || !val.contains('@'))
                ? 'Geçerli bir mail giriniz'
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildStep3() {
    return Form(
      key: _step3Key,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppInputField(
            controller: widget.passwordController,
            type: AppInputType.newPassword,
            label: "Şifre",
            leadingIcon: Icons.lock_outline,
            textInputAction: TextInputAction.next,
            validator: (val) =>
                (val == null || val.length < 6) ? 'En az 6 karakter' : null,
          ),
          const SizedBox(height: 12),
          AppInputField(
            controller: widget.confirmPasswordController,
            type: AppInputType.password,
            label: "Şifre Tekrar",
            leadingIcon: Icons.lock_reset,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _submit(),
            validator: (val) {
              if (val == null || val.isEmpty) return 'Tekrar giriniz';
              if (val != widget.passwordController.text) {
                return 'Şifreler uyuşmuyor';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 450),
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: AutofillGroup(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // STEP HEADERS (Optional, could add simple 1/3 indicator here)
            Text(
              "Adım ${_currentStep + 1} / 3",
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
            const SizedBox(height: 16),
            
            // FORM FIELDS
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.05, 0),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: KeyedSubtree(
                key: ValueKey<int>(_currentStep),
                child: _currentStep == 0
                    ? _buildStep1()
                    : _currentStep == 1
                        ? _buildStep2()
                        : _buildStep3(),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // NAVIGATION BUTTONS
            Row(
              children: [
                if (_currentStep > 0) ...[
                  Expanded(
                    flex: 1,
                    child: AppButton(
                      text: "Geri Dön",
                      onPressed: _prevStep,
                      variant: AppButtonVariant.secondary,
                      style: AppButtonStyle.outlined, // Outlined siyah olacak şekilde tasarlanmış AppButton kuralına uyar
                      size: AppButtonSize.medium,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  flex: 2,
                  child: AppButton(
                    text: _currentStep == 2 ? "Hesap Oluştur" : "Devam Et",
                    isLoading: widget.authProvider.isLoading,
                    onPressed: _currentStep == 2 ? _submit : _nextStep,
                    size: AppButtonSize.medium,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ],
            ),

            // OAUTH OPTIONS (Only on step 1)
            if (_currentStep == 0) ...[
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
            ],
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
