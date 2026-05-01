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
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';
import 'package:helmove/core/enums/user_tier.dart';
import 'package:helmove/features/auth/presentation/providers/auth_provider.dart';
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

  // Returns the monthly price string from an offering, or a fallback.
  String _monthlyPrice(Offerings? offerings, String offeringId, String fallback) {
    final offering = offerings?.getOffering(offeringId);
    if (offering == null) return fallback;
    // Prefer monthly package; fall back to first available package.
    final pkg = offering.monthly ?? (offering.availablePackages.isNotEmpty ? offering.availablePackages.first : null);
    return pkg?.storeProduct.priceString ?? fallback;
  }

  List<PlanModel> _buildPlanModels(Offerings? offerings, AppLocalizations l10n) {
    final plusOffering = offerings?.getOffering('plus_offering');
    final proOffering = offerings?.getOffering('pro_offering');

    return [
      PlanModel(
        title: l10n.free,
        price: '₺0',
        period: '/sonsuza dek',
        productId: 'free',
        features: [
          l10n.map_access,
          l10n.group_ride_participation,
          l10n.ad_supported_experience,
        ],
        gradientColors: const [Color(0xFF606c88), Color(0xFF3f4c6b)],
      ),
      PlanModel(
        title: 'HELMOVE PLUS ACCESS',
        price: _monthlyPrice(offerings, 'plus_offering', '₺149,99'),
        period: '/ay',
        productId: 'plus_offering',
        rcOffering: plusOffering,
        features: [
          l10n.ad_free_experience,
          l10n.unlimited_route_recording,
          'Gelişmiş Sosyal Akış',
          'Plus Rider Rozeti',
        ],
        gradientColors: const [Color(0xFF2193b0), Color(0xFF6dd5ed)],
      ),
      PlanModel(
        title: 'HELMOVE PRO ACCESS',
        price: _monthlyPrice(offerings, 'pro_offering', '₺249,99'),
        period: '/ay',
        productId: 'pro_offering',
        rcOffering: proOffering,
        features: [
          l10n.unlimited_communication,
          l10n.rider_radar,
          l10n.road_captain_tools,
          'Premium Harita Katmanları',
          'Detaylı Sürüş Analitiği',
        ],
        gradientColors: const [Color(0xFFf12711), Color(0xFFf5af19)],
      ),
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
                    listener: (context, state) {
                      // Restore purchase success (triggered from RestorePurchasesEvent, not paywall).
                      if (state.purchaseStatus == PurchaseStatus.success && state.successMessage != null) {
                        context.read<AuthProvider>().refreshCurrentUser();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(state.successMessage!)),
                        );
                      } else if (state.purchaseStatus == PurchaseStatus.failure) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(state.errorMessage ?? 'İşlem başarısız'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    builder: (context, state) {
                      // Show spinner only on first load (offerings == null and still loading).
                      if (state.status == SubscriptionStatus.loading && state.offerings == null) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final plans = _buildPlanModels(state.offerings, l10n);

                      // Active tier: prefer the live RevenueCat tier from state,
                      // fall back to the tier stored in AuthProvider.
                      final activeTier = state.currentTier != UserTier.free
                          ? state.currentTier
                          : (context.read<AuthProvider>().currentUser?.tier ?? UserTier.free);

                      return Column(
                        children: [
                          PlanTabSelector(
                            plans: plans,
                            currentIndex: _currentIndex,
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
                                final isSelected = _currentIndex == index;

                                final isActive = switch (activeTier) {
                                  UserTier.pro   => plan.productId.contains('pro'),
                                  UserTier.plus  => plan.productId.contains('plus') || plan.productId.contains('club'),
                                  UserTier.free  => plan.productId == 'free',
                                };

                                return AnimatedScale(
                                  scale: isSelected ? 1.0 : 0.9,
                                  duration: const Duration(milliseconds: 300),
                                  child: PremiumPlanCard(
                                    plan: plan,
                                    isSelected: isSelected,
                                    isActive: isActive,
                                    onBuyTap: () async {
                                      if (plan.productId == 'free') return;

                                      // Already premium → open Customer Center for management.
                                      if (state.isPremium) {
                                        await sl<SubscriptionService>().presentCustomerCenter();
                                        return;
                                      }

                                      // Open the RevenueCat paywall for this specific offering.
                                      final result = await sl<SubscriptionService>()
                                          .presentPaywall(offeringId: plan.productId);

                                      AppLogger.info('Paywall result [${plan.productId}]: $result');

                                      if ((result == PaywallResult.purchased || result == PaywallResult.restored) && context.mounted) {
                                        // CustomerInfo listener will auto-sync backend.
                                        // Refresh AuthProvider so the badge/tier in the rest of the app updates too.
                                        context.read<AuthProvider>().refreshCurrentUser();
                                        context.read<SubscriptionBloc>().add(const CheckPremiumStatusEvent());
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Helmove Dünyasına Hoş Geldin! 🎉')),
                                        );
                                      }
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
