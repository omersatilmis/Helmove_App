import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// ⚠️ Proje ismini kontrol et
import 'package:moto_comm_app_1/core/widgets/app_button.dart';
import 'package:moto_comm_app_1/core/widgets/app_input_field.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  // --- CONTROLLERLAR ---
  final _usernameController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

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

  @override
  Widget build(BuildContext context) {
    // 🎨 ARTIK TEMAYI MERKEZDEN ALIYORUZ
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // 1. HEADER (Kayıt Özel Tasarımı)
              _buildRegisterHeader(size, theme),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    const SizedBox(height: 20),

                    // 2. KULLANICI ADI
                    AppInputField(
                      controller: _usernameController,
                      type: AppInputType.standard,
                      label: "Kullanıcı Adı",
                      leadingIcon: Icons.alternate_email,
                      validator: (val) => (val == null || val.length < 3) 
                          ? 'En az 3 karakter giriniz' : null,
                    ),
                    
                    const SizedBox(height: 16),

                    // 3. AD ve SOYAD (Yan Yana)
                    Row(
                      children: [
                        Expanded(
                          child: AppInputField(
                            controller: _firstNameController,
                            type: AppInputType.firstName,
                            label: "Ad",
                            validator: (val) => (val == null || val.isEmpty) ? 'Gerekli' : null,
                          ),
                        ),
                        const SizedBox(width: 12), // Aradaki boşluk
                        Expanded(
                          child: AppInputField(
                            controller: _lastNameController,
                            type: AppInputType.lastName,
                            label: "Soyad",
                            validator: (val) => (val == null || val.isEmpty) ? 'Gerekli' : null,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // 4. E-POSTA
                    AppInputField(
                      controller: _emailController,
                      type: AppInputType.email,
                      label: "E-Posta",
                      leadingIcon: Icons.email_outlined,
                      validator: (val) => (val == null || !val.contains('@')) 
                          ? 'Geçerli bir mail giriniz' : null,
                    ),

                    const SizedBox(height: 16),

                    // 5. ŞİFRE
                    AppInputField(
                      controller: _passwordController,
                      type: AppInputType.password,
                      label: "Şifre",
                      leadingIcon: Icons.lock_outline,
                      validator: (val) => (val == null || val.length < 6) 
                          ? 'En az 6 karakter' : null,
                    ),

                    const SizedBox(height: 16),

                    // 6. ŞİFRE TEKRAR
                    AppInputField(
                      controller: _confirmPasswordController,
                      type: AppInputType.password,
                      label: "Şifre Tekrar",
                      leadingIcon: Icons.lock_reset,
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Şifreyi tekrar girin';
                        if (val != _passwordController.text) return 'Şifreler uyuşmuyor';
                        return null;
                      },
                    ),

                    const SizedBox(height: 32),

                    // 7. REGISTER BUTTON
                    AppButton(
                      text: "Hesap Oluştur",
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          // Kayıt Başarılı -> Home'a yönlendir
                          context.go('/home');
                        }
                      },
                      isFullWidth: true,
                      size: AppButtonSize.large,
                      borderRadius: BorderRadius.circular(16),
                    ),

                    const SizedBox(height: 24),

                    // 8. ALT LİNK (Giriş Yap)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Zaten hesabınız var mı?", style: theme.textTheme.bodyMedium),
                        TextButton(
                          onPressed: () {
                            context.pop(); // Login sayfasına geri dön
                          },
                          child: Text(
                            "Giriş Yap",
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 12),

                    // 5. AYIRAÇ
                    Row(
                      children: [
                        Expanded(child: Divider(color: theme.colorScheme.outlineVariant)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text("veya devam et", style: theme.textTheme.bodySmall),
                        ),
                        Expanded(child: Divider(color: theme.colorScheme.outlineVariant)),
                      ],
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // 6. GOOGLE GİRİŞ
                    AppButton(
                      text: "Google ile Giriş Yap",
                      onPressed: () {},
                      variant: AppButtonVariant.secondary,
                      style: AppButtonStyle.outlined,
                      isFullWidth: true,
                      icon: Icons.g_mobiledata,
                    ),
                    
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // HEADER TASARIMI
  Widget _buildRegisterHeader(Size size, ThemeData theme) {
    // Header rengini moda göre ayarlıyoruz (Login ile aynı mantık)
    final headerColor = theme.brightness == Brightness.light 
        ? theme.colorScheme.secondary 
        : theme.colorScheme.surfaceContainerLow;

    return Stack(
      children: [
        // Arka Plan
        Container(
          height: size.height * 0.25, // Kayıt formu uzun olduğu için header daha kısa
          width: double.infinity,
          decoration: BoxDecoration(
            color: headerColor,
          ),
        ),
        
        // Dalga Efekti
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: SizedBox(
            height: 60, 
            child: CustomPaint(
              painter: WavePainter(color: theme.colorScheme.surface),
            ),
          ),
        ),

        // Başlık ve Geri Dön Butonu
        Positioned.fill(
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Kayıt Ol",
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    "Hesabınızı oluşturun",
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Ortak kullanılacak WavePainter (İleride core/widgets altına taşınabilir)
class WavePainter extends CustomPainter {
  final Color color;
  WavePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..style = PaintingStyle.fill;
    final path = Path();
    final w = size.width;
    final h = size.height;
    
    path.moveTo(0, h * 0.75);
    path.cubicTo(w * 0.28, h * 0.5, w * 0.72, h, w, 0);
    path.lineTo(w, h);
    path.lineTo(0, h);
    path.close();
    
    canvas.drawPath(path, paint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
