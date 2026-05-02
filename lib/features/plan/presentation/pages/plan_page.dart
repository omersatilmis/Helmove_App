import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:helmove/core/constants/subscription_products.dart';
import 'package:helmove/core/di/injection_container.dart';
import 'package:helmove/core/theme/app_colors.dart';
import 'package:helmove/core/theme/text_styles.dart';
import 'package:helmove/features/plan/presentation/widgets/plan_model.dart';
import 'package:helmove/features/plan/presentation/widgets/premium_plan_card.dart';
import 'package:helmove/features/plan/presentation/widgets/plan_tab_selector.dart';
import 'package:helmove/core/widgets/app_frosted_button.dart';
import 'package:helmove/core/services/subscription_service.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:helmove/core/enums/user_tier.dart';
import 'package:helmove/features/auth/presentation/providers/auth_provider.dart';
import 'package:helmove/features/plan/domain/entities/subscription_plan_entity.dart';
import 'package:helmove/l10n/app_localizations.dart';
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
        ..add(const LoadOfferingsEvent())
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
  int _currentIndex = 0;

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

  List<Package> _revenueCatPackages(Offerings? offerings) {
    if (offerings == null) return const [];

    final packagesByProductId = <String, Package>{};
    final allOfferings = [
      if (offerings.current != null) offerings.current!,
      ...offerings.all.values,
    ];

    for (final offering in allOfferings) {
      for (final package in offering.availablePackages) {
        final productId = package.storeProduct.identifier;
        if (SubscriptionProducts.isKnownProductId(productId)) {
          packagesByProductId.putIfAbsent(productId, () => package);
        }
      }
    }

    final packages = packagesByProductId.values.toList()
      ..sort((a, b) {
        return SubscriptionProducts.sortIndex(
          a.storeProduct.identifier,
        ).compareTo(SubscriptionProducts.sortIndex(b.storeProduct.identifier));
      });
    return packages;
  }

  Map<String, SubscriptionPlanEntity> _backendPlansByCode(
    List<SubscriptionPlanEntity> plans,
  ) {
    return {
      for (final plan in plans)
        if (plan.code.trim().isNotEmpty) plan.code: plan,
    };
  }

  List<String> _fallbackFeatures(UserTier tier, AppLocalizations l10n) {
    return switch (tier) {
      UserTier.pro => [
        l10n.unlimited_communication,
        l10n.rider_radar,
        l10n.road_captain_tools,
        'Premium Harita Katmanları',
        'Detaylı Sürüş Analitiği',
      ],
      UserTier.plus => [
        l10n.ad_free_experience,
        l10n.unlimited_route_recording,
        'Gelişmiş Sosyal Akış',
        'Plus Rider Rozeti',
      ],
      UserTier.free => [
        l10n.map_access,
        l10n.group_ride_participation,
        l10n.ad_supported_experience,
      ],
    };
  }

  String _periodLabel(StoreProduct product, String productId) {
    return switch (product.subscriptionPeriod) {
      'P1M' => '/ay',
      'P6M' => '/6 ay',
      'P1Y' => '/yıl',
      _ => SubscriptionProducts.periodLabelForProductId(productId),
    };
  }

  List<PlanModel> _buildPlanModels(
    Offerings? offerings,
    List<SubscriptionPlanEntity> backendPlans,
    AppLocalizations l10n,
  ) {
    final backendByCode = _backendPlansByCode(backendPlans);
    final paidPlans = _revenueCatPackages(offerings).map((package) {
      final product = package.storeProduct;
      final productId = product.identifier;
      final tier = SubscriptionProducts.tierForProductId(productId);
      final backendPlan = backendByCode[productId];
      final backendDescription = backendPlan?.fullDescription.isNotEmpty == true
          ? backendPlan!.fullDescription
          : backendPlan?.description ?? '';

      return PlanModel(
        title: SubscriptionProducts.titleForProductId(productId),
        price: product.priceString,
        period: _periodLabel(product, productId),
        description: backendDescription,
        productId: productId,
        tierIndex: tier.tierIndex,
        badge: backendPlan?.badge,
        rcPackage: package,
        features: backendPlan?.features.isNotEmpty == true
            ? backendPlan!.features
            : _fallbackFeatures(tier, l10n),
        gradientColors: tier == UserTier.pro
            ? const [Color(0xFFf12711), Color(0xFFf5af19)]
            : const [Color(0xFF2193b0), Color(0xFF6dd5ed)],
      );
    }).toList();

    return [
      PlanModel(
        title: l10n.free,
        price: '₺0',
        period: '/sonsuza dek',
        productId: 'free',
        tierIndex: UserTier.free.tierIndex,
        features: _fallbackFeatures(UserTier.free, l10n),
        gradientColors: const [Color(0xFF606c88), Color(0xFF3f4c6b)],
      ),
      ...paidPlans,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final size = MediaQuery.sizeOf(context);
    final scale = (size.width / 375).clamp(0.9, 1.1);
    final sectionSpacing = (size.height * 0.03).clamp(16.0, 30.0);
    final horizontalPadding = (size.width * 0.05).clamp(16.0, 24.0);

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
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      AppFrostedButton(
                        icon: Icons.arrow_back_ios_new_rounded,
                        onTap: () => context.pop(),
                      ),
                      Expanded(
                        child: Text(
                          l10n.select_plan,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.h3.copyWith(
                            fontSize: 22 * scale,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
                SizedBox(height: sectionSpacing),
                Expanded(
                  child: BlocConsumer<SubscriptionBloc, SubscriptionState>(
                    listenWhen: (previous, current) {
                      return previous.purchaseStatus !=
                              current.purchaseStatus ||
                          previous.successMessage != current.successMessage ||
                          previous.errorMessage != current.errorMessage;
                    },
                    listener: (context, state) {
                      if (state.purchaseStatus == PurchaseStatus.success &&
                          state.successMessage != null) {
                        context.read<AuthProvider>().refreshCurrentUser();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(state.successMessage!)),
                        );
                      } else if (state.purchaseStatus ==
                          PurchaseStatus.failure) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              state.errorMessage ?? 'İşlem başarısız',
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    builder: (context, state) {
                      final plans = _buildPlanModels(
                        state.offerings,
                        state.plans,
                        l10n,
                      );

                      final authTier =
                          context.watch<AuthProvider>().currentUser?.tier ??
                          UserTier.free;
                      final activeTier =
                          state.currentTier.tierIndex >= authTier.tierIndex
                          ? state.currentTier
                          : authTier;
                      final safeIndex = plans.isEmpty
                          ? 0
                          : _currentIndex.clamp(0, plans.length - 1).toInt();

                      return Column(
                        children: [
                          PlanTabSelector(
                            plans: plans,
                            currentIndex: safeIndex,
                            onTabSelected: _onTabSelected,
                          ),
                          SizedBox(height: sectionSpacing),
                          Expanded(
                            child: PageView.builder(
                              controller: _pageController,
                              itemCount: plans.length,
                              onPageChanged: (index) =>
                                  setState(() => _currentIndex = index),
                              itemBuilder: (context, index) {
                                final plan = plans[index];
                                final isSelected = safeIndex == index;
                                final isActive = plan.tierIndex == 0
                                    ? activeTier.tierIndex == 0
                                    : activeTier.tierIndex >= plan.tierIndex;

                                return AnimatedScale(
                                  scale: isSelected ? 1.0 : 0.9,
                                  duration: const Duration(milliseconds: 300),
                                  child: PremiumPlanCard(
                                    plan: plan,
                                    isSelected: isSelected,
                                    isActive: isActive,
                                    onBuyTap: () async {
                                      if (plan.productId == 'free') return;
                                      if (state.purchaseStatus ==
                                          PurchaseStatus.loading) {
                                        return;
                                      }

                                      if (activeTier.tierIndex >=
                                          plan.tierIndex) {
                                        await sl<SubscriptionService>()
                                            .presentCustomerCenter();
                                        return;
                                      }

                                      final package = plan.rcPackage;
                                      if (package == null) return;
                                      context.read<SubscriptionBloc>().add(
                                        PurchasePackageEvent(package),
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
                                  l10n.restore_purchases,
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
