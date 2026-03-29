import 'package:flutter/material.dart';
import 'package:helmove/core/theme/text_styles.dart';
import 'package:helmove/features/plan/presentation/widgets/plan_model.dart';

class PremiumPlanCard extends StatelessWidget {
  final PlanModel plan;
  final bool isSelected;
  final bool isActive;
  final VoidCallback onBuyTap;

  const PremiumPlanCard({
    super.key,
    required this.plan,
    required this.isSelected,
    this.isActive = false,
    required this.onBuyTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor =
        isDark ? theme.colorScheme.onSurface : theme.colorScheme.onSurface;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : 560.0;
        final scale = (width / 360).clamp(0.9, 1.1);
        final headerHeight = (height * 0.28).clamp(96.0, 130.0);
        final contentPadding = (width * 0.06).clamp(16.0, 24.0);
        final buttonHeight = (54 * scale).clamp(48.0, 56.0);

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            // Kart arka planı: Helmove estetiği için Dark modda derinlik kazandırıldı
            color: isDark
                ? const Color(0xFF1E1E1E)
                : theme.colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: plan.gradientColors.first.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
            border: isSelected
                ? Border.all(color: plan.gradientColors.first, width: 2)
                : null,
          ),
          child: Column(
            children: [
              // -----------------------------------------------------------
              // 1. KART BAŞLIĞI (Gradiyent Alan)
              // -----------------------------------------------------------
              Container(
                height: headerHeight,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(28),
                  ),
                  gradient: LinearGradient(
                    colors: plan.gradientColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                alignment: Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          plan.title,
                          style: AppTextStyles.h2.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.1,
                            fontSize: 20 * scale,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 8 * scale),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            plan.price,
                            style: AppTextStyles.h1.copyWith(
                              color: Colors.white,
                              fontSize: 30 * scale,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            plan.period,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: Colors.white70,
                              fontSize: 12 * scale,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // -----------------------------------------------------------
              // 2. ÖZELLİKLER LİSTESİ
              // -----------------------------------------------------------
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(contentPadding),
                  child: Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Column(
                            children: [
                              ...plan.features.map(
                                (feature) => Padding(
                                  padding: EdgeInsets.only(
                                    bottom: 12 * scale,
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Şık Tik Kutusu
                                      Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: plan.gradientColors.first
                                              .withValues(alpha: 0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.check,
                                          size: 16 * scale,
                                          color: plan.gradientColors.first,
                                        ),
                                      ),
                                      SizedBox(width: 10 * scale),
                                      // Özellik Metni (Dark/Light Uyumlu)
                                      Expanded(
                                        child: Text(
                                          feature,
                                          style: AppTextStyles.regular.copyWith(
                                            color: textColor,
                                            fontSize: 13 * scale,
                                            height: 1.35,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(height: 12 * scale),

                      // -----------------------------------------------------------
                      // 3. SATIN AL BUTONU (Tetikleyici) VEYA AKTİF DURUMU
                      // -----------------------------------------------------------
                      SizedBox(
                        width: double.infinity,
                        height: buttonHeight,
                        child: isActive
                            ? Container(
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF2C2C2C)
                                      : theme.colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(27),
                                  border: Border.all(
                                    color: plan.gradientColors.first
                                        .withValues(alpha: 0.5),
                                    width: 1,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.check_circle_rounded,
                                      color: plan.gradientColors.first,
                                      size: 20 * scale,
                                    ),
                                    SizedBox(width: 8 * scale),
                                    Flexible(
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          "Mevcut Planınız",
                                          style: AppTextStyles.button.copyWith(
                                            fontSize: 15 * scale,
                                            color: textColor.withValues(
                                              alpha: 0.8,
                                            ),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ElevatedButton(
                                onPressed: onBuyTap,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  padding: EdgeInsets.zero,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(27),
                                  ),
                                ),
                                child: Ink(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: plan.gradientColors,
                                    ),
                                    borderRadius: BorderRadius.circular(27),
                                  ),
                                  child: Container(
                                    alignment: Alignment.center,
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        "HEMEN BAŞLA",
                                        style: AppTextStyles.button.copyWith(
                                          fontSize: 15 * scale,
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
