import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// ⚠️ Proje ismini kontrol et
import 'package:moto_comm_app_1/core/widgets/app_button.dart';
import 'package:moto_comm_app_1/core/widgets/app_input_field.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // Controller'lar
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  // State
  bool _rememberMe = false;
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 🎨 ARTIK TEMAYI MERKEZDEN ALIYORUZ
    // Manuel renk tanımlarına gerek kalmadı!
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              
              // 1. KAVİSLİ (WAVE) BAŞLIK ALANI
              _buildCurvedHeader(size, theme),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 20),

                    // 2. INPUT ALANLARI
                    AppInputField(
                      controller: _emailController,
                      type: AppInputType.email,
                      label: "E-Posta",
                      leadingIcon: Icons.email_outlined,
                      validator: (val) => (val == null || !val.contains('@')) 
                          ? 'Geçerli bir e-posta girin' : null,
                    ),
                    
                    const SizedBox(height: 20),
                    
                    AppInputField(
                      controller: _passwordController,
                      type: AppInputType.password,
                      label: "Şifre",
                      leadingIcon: Icons.lock_outline,
                      validator: (val) => (val == null || val.length < 6) 
                          ? 'En az 6 karakter gerekli' : null,
                    ),

                    // 3. BENİ HATIRLA & ŞİFREMİ UNUTTUM
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Checkbox(
                              value: _rememberMe,
                              // Checkbox teması AppTheme'den otomatik gelir
                              onChanged: (val) => setState(() => _rememberMe = val ?? false),
                            ),
                            Text("Beni Hatırla", style: theme.textTheme.bodyMedium),
                          ],
                        ),
                        TextButton(
                          onPressed: () {},
                          child: Text(
                            "Şifremi Unuttum?",
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // 4. GİRİŞ BUTONU
                    AppButton(
                      text: "Giriş Yap",
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          // Başarılı giriş, Home sayfasına git
                          context.go('/home');
                        }
                      },
                      isFullWidth: true,
                      size: AppButtonSize.large,
                      borderRadius: BorderRadius.circular(16),
                    ),

                    const SizedBox(height: 32),

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

                    // 7. KAYIT OL LİNKİ
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Hesabınız yok mu?", style: theme.textTheme.bodyMedium),
                        TextButton(
                          onPressed: () {
                            // Kayıt sayfasına git
                            context.push('/register'); 
                          },
                          child: Text(
                            "Kayıt Ol",
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // -----------------------------------------------------------
  // 🌊 HEADER YAPISI
  // -----------------------------------------------------------
  Widget _buildCurvedHeader(Size size, ThemeData theme) {
    // Header rengini moda göre ayarlıyoruz:
    // Light Mod: Secondary (Koyu Gri)
    // Dark Mod: SurfaceContainerLow (Koyu Gri - Antrasit)
    // Böylece her iki modda da yazı beyaz kalır ve okunur.
    final headerColor = theme.brightness == Brightness.light 
        ? theme.colorScheme.secondary 
        : theme.colorScheme.surfaceContainerLow;

    return Stack(
      children: [
        // KATMAN 1: Koyu Arka Plan
        Container(
          height: size.height * 0.40,
          width: double.infinity,
          decoration: BoxDecoration(
            color: headerColor, 
          ),
        ),

        // KATMAN 2: Wave Shape (Beyaz/Siyah Dalga)
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: SizedBox(
            height: 100,
            child: CustomPaint(
              // Dalga rengi sayfanın zemin rengiyle aynı olmalı ki bütünleşsin
              painter: WavePainter(color: theme.colorScheme.surface),
            ),
          ),
        ),

        // KATMAN 3: İçerik
        Positioned.fill(
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Spacer(flex: 2), 
                  
                  Icon(
                    Icons.two_wheeler,
                    size: 64,
                    color: theme.colorScheme.primary, // Turuncu İkon
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "İyi Sürüşler,",
                    style: theme.textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: Colors.white, // Koyu zemin üstünde beyaz yazı
                      letterSpacing: -0.5,
                    ),
                  ),
                  Text(
                    "Hesabınıza giriş yapın.",
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                  
                  const Spacer(flex: 3),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// -----------------------------------------------------------
// 🎨 WAVE PAINTER
// -----------------------------------------------------------
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
