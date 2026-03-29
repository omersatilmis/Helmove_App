import 'package:flutter/material.dart';
import 'package:helmove/core/theme/text_styles.dart';
import 'package:helmove/features/plan/presentation/widgets/plan_model.dart';

class PlanTabSelector extends StatelessWidget {
  final List<PlanModel> plans;
  final int currentIndex;
  final Function(int) onTabSelected;

  const PlanTabSelector({
    super.key,
    required this.plans,
    required this.currentIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.sizeOf(context);
    final scale = (size.width / 375).clamp(0.9, 1.1);
    final horizontalMargin = (size.width * 0.08).clamp(16.0, 40.0);
    final height = (size.height * 0.06).clamp(42.0, 54.0);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: horizontalMargin),
      height: height,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(height / 2),
      ),
      // LayoutBuilder: Ekran genişliğini almamızı sağlar, böylece kayma mesafesini hesaplarız.
      child: plans.isEmpty
          ? const SizedBox.shrink()
          : LayoutBuilder(
              builder: (context, constraints) {
                // Bir sekmenin genişliğini hesapla (Toplam Genişlik / Sekme Sayısı)
                final double tabWidth = constraints.maxWidth / plans.length;

                // Index güvenliği
                final safeIndex = currentIndex.clamp(0, plans.length - 1);

                return Stack(
                  children: [
                    // 1. KATMAN: KAYAN RENKLİ KUTU (ANIMASYON BURADA)
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves
                          .easeInOutCubic, // Yumuşak ve havalı bir geçiş eğrisi
                      left:
                          safeIndex *
                          tabWidth, // Hangi sıradaysa o kadar sağa kaydır
                      top: 0,
                      bottom: 0,
                      width: tabWidth,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(height / 2),
                          // Seçili planın gradient rengini al
                          gradient: LinearGradient(
                            colors: plans[safeIndex].gradientColors,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: plans[safeIndex].gradientColors.first
                                  .withValues(alpha:0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // 2. KATMAN: YAZILAR VE TIKLAMA ALANLARI
                    Row(
                      children: List.generate(plans.length, (index) {
                        final isSelected = currentIndex == index;
                        final plan = plans[index];

                        return Expanded(
                          child: GestureDetector(
                            onTap: () => onTabSelected(index),
                            behavior: HitTestBehavior
                                .translucent, // Boşluklara tıklamayı da algıla
                            child: Container(
                              alignment: Alignment.center,
                              child: AnimatedDefaultTextStyle(
                                duration: const Duration(milliseconds: 200),
                                style: AppTextStyles.medium.copyWith(
                                  // Seçiliyse Beyaz, değilse Gri
                                  color: isSelected
                                      ? Colors.white
                                      : theme.colorScheme.onSurface
                                          .withValues(alpha: 0.6),
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  fontSize: 12 * scale,
                                ),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    plan.title,
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                );
              },
            ),
    );
  }
}
