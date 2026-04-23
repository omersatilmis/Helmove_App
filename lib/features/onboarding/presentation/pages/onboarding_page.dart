import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
      title: 'Birlikte Sür, Her yerde Bağlı Kal',
      description: 'Paylaş, mesajlaş, ve motorcularla bir topluluğun parçası ol.',
    ),
    OnboardPageData(
      imagePath: 'assets/images/onboard2.png',
      title: 'Sürüşünü Planla',
      description: 'Rotalar oluştur, grup sürüşleri organize et, ve harita üzerinde rotanı paylaş.',
    ),
    OnboardPageData(
      imagePath: 'assets/images/onboard3.png',
      title: 'Akıllı Sürüş',
      description: 'Yapay Zeka desteği ile akıllı, güvenli ve eğlenceli sürüşün tadını çıkar.',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNext() async {
    if (_currentPage < pages.length - 1) {
      _pageController.animateToPage(
        _currentPage + 1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeIn,
      );
    } else {
      // --- ONBOARDING BİTTİ ---
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onboarding_shown', true);
      
      // go_router kullanarak ana yetkilendirme (pre-auth) sayfasına geçiş
      if (mounted) {
        context.go('/pre-auth');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Ekran boyutlarına göre orantılı değerler
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: pages.length,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    final onboard = pages[index];
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.asset(
                            onboard.imagePath,
                            width: double.infinity,
                            height: screenHeight * 0.35,
                            fit: BoxFit.cover,
                            // Resim bulunamazsa çökmeyi önlemek için placeholder:
                            errorBuilder: (context, error, stackTrace) => Container(
                              width: double.infinity,
                              height: screenHeight * 0.35,
                              color: Colors.grey.shade300,
                              child: const Icon(Icons.image, size: 50, color: Colors.grey),
                            ),
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.03),
                        Text(
                          onboard.title,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: screenWidth * 0.06,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.02),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
                          child: Text(
                            onboard.description,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: screenWidth * 0.045,
                              height: 1.5,
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

              // Yatay Gösterge (Horizontal Pager Indicator)
              Padding(
                padding: EdgeInsets.symmetric(vertical: screenHeight * 0.02),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    pages.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      height: 8,
                      width: _currentPage == index ? 24 : 8,
                      decoration: BoxDecoration(
                        color: _currentPage == index
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),

              // İleri/Başla Butonu
              Padding(
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.08),
                child: SizedBox(
                  width: double.infinity,
                  height: screenHeight * 0.07,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _onNext,
                    child: Text(
                      _currentPage == pages.length - 1 ? "Başla" : "Next",
                      style: TextStyle(fontSize: screenWidth * 0.045),
                    ),
                  ),
                ),
              ),
              SizedBox(height: screenHeight * 0.02),
            ],
          ),
        ),
      ),
    );
  }
}
