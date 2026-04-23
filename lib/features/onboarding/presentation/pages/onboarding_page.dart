import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:helmove/core/widgets/app_button.dart';

class OnboardPageData {
  final String imagePath;
  final String title;
  final String description;

  OnboardPageData({
    required this.imagePath,
    required this.title,
    required this.description,
  });
}

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardPageData> pages = [
    OnboardPageData(
      imagePath: 'assets/images/onboard1.png',
      title: 'Birlikte Sür, Her Yerde Bağlı Kal',
      description:
          'Paylaş, mesajlaş ve motorcularla bir topluluğun parçası ol.',
    ),
    OnboardPageData(
      imagePath: 'assets/images/onboard2.png',
      title: 'Sürüşünü Planla',
      description:
          'Rotalar oluştur, grup sürüşleri organize et ve harita üzerinde rotanı paylaş.',
    ),
    OnboardPageData(
      imagePath: 'assets/images/onboard3.png',
      title: 'Akıllı Sürüş Deneyimi',
      description:
          'Yapay Zeka desteği ile akıllı, güvenli ve eğlenceli sürüşün tadını çıkar.',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onFinish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_shown', true);
    if (mounted) {
      context.go('/pre-auth');
    }
  }

  void _onNext() {
    if (_currentPage < pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _onFinish();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Ana İçerik (PageView)
          PageView.builder(
            controller: _pageController,
            itemCount: pages.length,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemBuilder: (context, index) {
              final onboard = pages[index];
              return Stack(
                children: [
                  // Üst Kısım: Resim ve Gradient Maske
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: size.height * 0.6,
                    child: ShaderMask(
                      shaderCallback: (rect) {
                        return LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black,
                            Colors.black.withValues(alpha: 0.8),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.6, 1.0],
                        ).createShader(
                          Rect.fromLTRB(0, 0, rect.width, rect.height),
                        );
                      },
                      blendMode: BlendMode.dstIn,
                      child: Image.asset(
                        onboard.imagePath,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: theme.colorScheme.surfaceContainerHighest,
                          child: Icon(
                            Icons.image,
                            size: 80,
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Alt Kısım: Metinler
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      height: size.height * 0.45,
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          const SizedBox(height: 20),
                          Text(
                            onboard.title,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: theme.colorScheme.onSurface,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            onboard.description,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.7,
                              ),
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

          // Üst Kontroller: "Geç" Butonu
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextButton(
                  onPressed: _onFinish,
                  child: Text(
                    "Geç",
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Alt Kontroller: Sayfa Göstergesi ve Buton
          Positioned(
            bottom: 40,
            left: 32,
            right: 32,
            child: Column(
              children: [
                // Sayfa Göstergesi (Indicator)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    pages.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      height: 6,
                      width: _currentPage == index ? 24 : 6,
                      decoration: BoxDecoration(
                        color: _currentPage == index
                            ? theme.colorScheme.primary
                            : theme.colorScheme.primary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Ana Buton
                AppButton(
                  text: _currentPage == pages.length - 1
                      ? "Hemen Başla"
                      : "İleri",
                  isFullWidth: true,
                  size: AppButtonSize.large,
                  icon: _currentPage == pages.length - 1
                      ? Icons.rocket_launch
                      : Icons.arrow_forward_rounded,
                  iconRight: true,
                  onPressed: _onNext,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
