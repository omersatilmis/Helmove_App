import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:helmove/core/di/injection_container.dart';
import 'package:helmove/core/theme/app_colors.dart';
import 'package:helmove/core/theme/text_styles.dart';
import 'package:helmove/features/plan/presentation/widgets/plan_model.dart';
import 'package:helmove/features/plan/presentation/widgets/premium_plan_card.dart';
import 'package:helmove/features/plan/presentation/widgets/plan_tab_selector.dart';
import 'package:helmove/core/widgets/app_frosted_button.dart';
import 'package:helmove/core/utils/app_logger.dart';
import 'package:helmove/core/services/subscription_service.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';
import 'package:helmove/features/auth/presentation/providers/auth_provider.dart';
import 'dart:io';
import '../bloc/subscription_bloc.dart';
import '../bloc/subscription_event.dart';
import '../bloc/subscription_state.dart';

class PlanPage extends StatelessWidget {
  const PlanPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<SubscriptionBloc>()
        ..add(const GetSubscriptionPlansEvent())
        ..add(const CheckPremiumStatusEvent()),
      child: const _PlanView(),
    );
  }
}

class _PlanView extends StatefulWidget {
  const _PlanView();

  @override
  State<_PlanView> createState() => _PlanViewState();
}

class _PlanViewState extends State<_PlanView> {
  late final PageController _pageController;
  int _currentIndex = 1; // Başlangıçta Plus paketini odakla

  @override
  void initState() {
    super.initState();
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

  void _onTabSelected(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  List<PlanModel> _mapEntitiesToModels(dynamic plans) {
    // Backend verisi gelene kadar markamıza uygun yeni statik veriler
    if (plans == null || plans.isEmpty) {
      return [
        PlanModel(
          title: "Ücretsiz",
          price: "₺0",
          period: "/sonsuza dek",
          productId: "free",
          features: [
            "Harita Erişimi",
            "Grup Sürüşlerine Katılım",
            "Reklamlı Deneyim",
          ],
          gradientColors: [
            const Color(0xFF606c88),
            const Color(0xFF3f4c6b),
          ], // Gri tonları
        ),
        PlanModel(
          title: "HELMOVE PLUS ACCESS",
          price: "₺149.99",
          period: "/ay",
          productId: "plus_offering", // Offering ID ile eşleşmesi için
          features: [
            "Reklamsız Safkan Deneyim",
            "Sınırsız Rota Kaydı",
            "Gelişmiş Sosyal Akış",
            "Plus Rider Rozeti",
          ],
          gradientColors: [
            const Color(0xFF2193b0),
            const Color(0xFF6dd5ed),
          ], // Mavi/Cyan
        ),
        PlanModel(
          title: "HELMOVE PRO ACCESS",
          price: "₺249.99",
          period: "/ay",
          productId: "pro_offering", // Offering ID ile eşleşmesi için
          features: [
            "Sınırsız & Özgür İletişim",
            "Rider Radar (Yakın Takip)",
            "Yol Kaptanı Araçları",
            "Premium Harita Katmanları",
            "Detaylı Sürüş Analitiği",
          ],
          gradientColors: [
            const Color(0xFFf12711),
            const Color(0xFFf5af19),
          ], // Turuncu/Kırmızı
        ),
      ];
    }

    // Backend'den gelen verileri map'leme (İhtiyaç olursa)
    return (plans as List<dynamic>).map((plan) {
      List<Color> colors = plan.code.contains('pro')
          ? [const Color(0xFFf12711), const Color(0xFFf5af19)]
          : [const Color(0xFF2193b0), const Color(0xFF6dd5ed)];

      return PlanModel(
        title: plan.name.toUpperCase(),
        price: "${plan.currency}${plan.price}",
        period: plan.durationDays >= 365 ? "/yıl" : "/ay",
        productId: plan.code,
        features: plan.features,
        gradientColors: colors,
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Arka plan dekorasyonu
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.1),
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
          SafeArea(
            child: Column(
              children: [
                // AppBar alanı
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
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
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                Expanded(
                  child: BlocConsumer<SubscriptionBloc, SubscriptionState>(
                    listener: (context, state) {
                      if (state.purchaseStatus == PurchaseStatus.success) {
                        context.read<AuthProvider>().refreshCurrentUser();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Helmove Dünyasına Hoş Geldin! 🎉"),
                          ),
                        );
                      } else if (state.purchaseStatus ==
                          PurchaseStatus.failure) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              state.errorMessage ?? "İşlem başarısız",
                            ),
                          ),
                        );
                      }
                    },
                    builder: (context, state) {
                      if (state.status == SubscriptionStatus.loading) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final plans = _mapEntitiesToModels(state.plans);

                      return Column(
                        children: [
                          PlanTabSelector(
                            plans: plans,
                            currentIndex: _currentIndex,
                            onTabSelected: _onTabSelected,
                          ),
                          const SizedBox(height: 30),
                          Expanded(
                            child: PageView.builder(
                              controller: _pageController,
                              itemCount: plans.length,
                              onPageChanged: (index) =>
                                  setState(() => _currentIndex = index),
                              itemBuilder: (context, index) {
                                final plan = plans[index];
                                final isSelected = _currentIndex == index;

                                // Kullanıcının mevcut paketini AuthProvider üzerinden al
                                final userTier = context.read<AuthProvider>().currentUser?.tier;
                                bool isActive = false;
                                if (userTier != null) {
                                  // Eğer Pro ise ve pro kartıysa
                                  if (userTier.name == 'pro' && plan.productId.contains('pro')) {
                                    isActive = true;
                                  } 
                                  // Eğer Plus ise ve plus/club kartıysa
                                  else if (userTier.name == 'plus' && (plan.productId.contains('plus') || plan.productId.contains('club'))) {
                                    isActive = true;
                                  }
                                  // Free kontrolü
                                  else if (userTier.name == 'free' && plan.productId == 'free') {
                                    isActive = true;
                                  }
                                }

                                return AnimatedScale(
                                  scale: isSelected ? 1.0 : 0.9,
                                  duration: const Duration(milliseconds: 300),
                                  child: PremiumPlanCard(
                                    plan: plan,
                                    isSelected: isSelected,
                                    isActive: isActive,
                                    onBuyTap: () async {
                                      // 1. Zaten premium mu?
                                      if (state.isPremium) {
                                        await sl<SubscriptionService>()
                                            .presentCustomerCenter();
                                        return;
                                      }

                                      // 2. Ücretsiz plan ise bir şey yapma
                                      if (plan.productId == "free") return;

                                      // 3. Paywall'u ilgili offering ID ile aç
                                      final result =
                                          await sl<SubscriptionService>()
                                              .presentPaywall(
                                                offeringId: plan.productId,
                                              );

                                      if (result == PaywallResult.purchased ||
                                          result == PaywallResult.restored) {
                                        if (context.mounted) {
                                          context.read<SubscriptionBloc>().add(
                                            const CheckPremiumStatusEvent(),
                                          );
                                        }
                                      }
                                      AppLogger.info(
                                        "Paywall Result for ${plan.title}: $result",
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
                          ),
                          if (Platform.isIOS || Platform.isAndroid)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 20),
                              child: TextButton(
                                onPressed: () {
                                  context.read<SubscriptionBloc>().add(
                                    const RestorePurchasesEvent(),
                                  );
                                },
                                child: Text(
                                  "Satın Alımları Geri Yükle",
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.6),
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ),
                        ],
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
