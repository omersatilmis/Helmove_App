import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:moto_comm_app_1/core/theme/app_colors.dart';
import 'package:moto_comm_app_1/core/theme/text_styles.dart';

// Modeller ve Widgetlar (Senin klasör yapına göre)
import 'package:moto_comm_app_1/features/plan/presentation/widgets/plan_model.dart';
import 'package:moto_comm_app_1/features/plan/presentation/widgets/premium_plan_card.dart';
import 'package:moto_comm_app_1/features/plan/presentation/widgets/plan_tab_selector.dart';
import 'package:moto_comm_app_1/core/widgets/app_button_frosted.dart'; // 👈 Import burada

class PlanPage extends StatefulWidget {
  const PlanPage({super.key});

  @override
  State<PlanPage> createState() => _PlanPageState();
}

class _PlanPageState extends State<PlanPage> {
  late final PageController _pageController;

  // Varsayılan olarak ORTADAKİ (1. index) plan seçili olsun
  int _currentIndex = 1;

  // 🔥 PLAN VERİLERİ
  final List<PlanModel> _plans = [
    PlanModel(
      title: "Ücretsiz",
      price: "₺0",
      period: "/sonsuza dek",
      productId: "free",
      features: [
        "Harita Erişimi",
        "Grup Sürüşlerine Katıl",
        "Reklamlı Deneyim",
      ],
      gradientColors: [const Color(0xFFEC008C), const Color(0xFFFC6767)],
    ),
    PlanModel(
      title: "Rider Pro",
      price: "₺49.99",
      period: "/ay",
      productId: "pro_monthly",
      features: [
        "Tüm Ücretsiz Özellikler",
        "Reklamsız Deneyim",
        "Sınırsız Rota Kaydı",
        "Canlı Konum (Ghost Mode)",
      ],
      gradientColors: [const Color(0xFF2193b0), const Color(0xFF6dd5ed)],
    ),
    PlanModel(
      title: "MotoClub",
      price: "₺99.99",
      period: "/ay",
      productId: "club_monthly",
      features: [
        "Tüm Pro Özellikler",
        "Özel Kulüp Rozeti",
        "Etkinlik Oluşturma",
        "İnterkom Özelliği (Beta)",
      ],
      gradientColors: [const Color(0xFFf12711), const Color(0xFFf5af19)],
    ),
  ];

  @override
  void initState() {
    super.initState();
    // ✅ Sayfa açıldığında direkt seçili index'e gitmesini sağlıyoruz
    _pageController = PageController(
      viewportFraction: 0.85,
      initialPage: _currentIndex,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // Tab'a basınca sayfayı kaydıran fonksiyon
  void _onTabSelected(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          // 1. ARKA PLAN DEKORU
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.2),
                // Blur (Bulanıklık) efekti BoxShadow ile verilir:
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    blurRadius: 100,
                    spreadRadius: 20,
                  ),
                ],
              ),
            ),
          ),

          // 2. ANA İÇERİK
          SafeArea(
            child: Column(
              children: [
                // ÜST BAŞLIK VE GERİ BUTONU
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // 🔥 GÜNCELLEME: Artık Core altındaki AppFrostedButton kullanılıyor
                      AppFrostedButton(
                        icon: Icons.arrow_back_ios_new_rounded,
                        onTap: () => context.pop(),
                      ),

                      Text(
                        "Planını Seç",
                        style: AppTextStyles.h3.copyWith(
                          fontSize: 22,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(width: 48), // Dengelemek için boşluk
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // TAB SEÇİCİ
                PlanTabSelector(
                  plans: _plans,
                  currentIndex: _currentIndex,
                  onTabSelected: _onTabSelected,
                ),

                const SizedBox(height: 30),

                // KARTLAR CAROUSEL
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _plans.length,
                    onPageChanged: (index) =>
                        setState(() => _currentIndex = index),
                    itemBuilder: (context, index) {
                      final plan = _plans[index];
                      final isSelected = _currentIndex == index;

                      return AnimatedScale(
                        scale: isSelected ? 1.0 : 0.9,
                        duration: const Duration(milliseconds: 300),
                        // KART WIDGET'I
                        child: PremiumPlanCard(
                          plan: plan,
                          isSelected: isSelected,
                          onBuyTap: () {
                            print(
                              "Satın al: ${plan.title} (${plan.productId})",
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
