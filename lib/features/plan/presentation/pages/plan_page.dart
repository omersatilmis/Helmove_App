import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:moto_comm_app_1/core/di/injection_container.dart';
import 'package:moto_comm_app_1/core/theme/app_colors.dart';
import 'package:moto_comm_app_1/core/theme/text_styles.dart';
import 'package:moto_comm_app_1/features/plan/presentation/widgets/plan_model.dart';
import 'package:moto_comm_app_1/features/plan/presentation/widgets/premium_plan_card.dart';
import 'package:moto_comm_app_1/features/plan/presentation/widgets/plan_tab_selector.dart';
import 'package:moto_comm_app_1/core/widgets/app_frosted_button.dart';
import '../bloc/subscription_bloc.dart';
import '../bloc/subscription_event.dart';
import '../bloc/subscription_state.dart';

class PlanPage extends StatelessWidget {
  const PlanPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          sl<SubscriptionBloc>()..add(const GetSubscriptionPlansEvent()),
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
  int _currentIndex = 1;

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
    // Backend'den veri gelmezse veya boş gelirse ESKİ TASARIMI KORUMAK İÇİN
    // statik dummy verileri göster.
    if (plans.isEmpty) {
      return [
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
    }

    return (plans as List<dynamic>).map((plan) {
      // Renkleri plan koduna göre belirle veya sırayla ata
      // Şimdilik basit bir mantıkla dönüyoruz
      List<Color> colors;
      if (plan.code.contains('free')) {
        colors = [const Color(0xFFEC008C), const Color(0xFFFC6767)];
      } else if (plan.code.contains('pro')) {
        colors = [const Color(0xFF2193b0), const Color(0xFF6dd5ed)];
      } else {
        colors = [const Color(0xFFf12711), const Color(0xFFf5af19)];
      }

      // Süre metnini formatla
      String periodText = "/ay";
      if (plan.durationDays >= 365) {
        periodText = "/yıl";
      } else if (plan.durationDays == 0) {
        periodText = "/sonsuza dek";
      }

      return PlanModel(
        title: plan.name,
        // Fiyatı formatla: ₺49.99 gibi
        price: "${plan.currency}${plan.price}",
        period: periodText,
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
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withOpacity(0.2),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.2),
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
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Abonelik başarılı! 🎉"),
                          ),
                        );
                      } else if (state.purchaseStatus ==
                          PurchaseStatus.failure) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(state.errorMessage ?? "Hata oluştu"),
                          ),
                        );
                      }
                    },
                    builder: (context, state) {
                      if (state.status == SubscriptionStatus.loading) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (state.status == SubscriptionStatus.failure) {
                        return Center(
                          child: Text(
                            state.errorMessage ?? "Planlar yüklenemedi",
                          ),
                        );
                      }

                      // Backend verisi geldiğinde burayı güncelleyeceğiz
                      // Şimdilik statik listeyi kullanıyoruz ama yapı hazır
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

                                return AnimatedScale(
                                  scale: isSelected ? 1.0 : 0.9,
                                  duration: const Duration(milliseconds: 300),
                                  child: PremiumPlanCard(
                                    plan: plan,
                                    isSelected: isSelected,
                                    onBuyTap: () {
                                      // Backend entegrasyonu için örnek tetikleme
                                      // context.read<SubscriptionBloc>().add(
                                      //   SubscribeToPlanEvent(
                                      //     planId: 1, // Örnek ID
                                      //     paymentProvider: 'stripe',
                                      //     transactionId: 'dummy_id',
                                      //   ),
                                      // );
                                      print("Satın al: ${plan.title}");
                                    },
                                  ),
                                );
                              },
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
