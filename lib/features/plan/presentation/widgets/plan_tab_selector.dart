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

    if (plans.isEmpty) return const SizedBox.shrink();

    final safeIndex = currentIndex.clamp(0, plans.length - 1).toInt();
    final chipWidth = (size.width * 0.3).clamp(92.0, 132.0);

    return SizedBox(
      height: height,
      child: ListView.separated(
        padding: EdgeInsets.symmetric(horizontal: horizontalMargin),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: plans.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final isSelected = safeIndex == index;
          final plan = plans[index];

          return GestureDetector(
            onTap: () => onTabSelected(index),
            behavior: HitTestBehavior.opaque,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: chipWidth,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(height / 2),
                gradient: isSelected
                    ? LinearGradient(colors: plan.gradientColors)
                    : null,
                color: isSelected
                    ? null
                    : theme.colorScheme.surfaceContainerHighest,
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: plan.gradientColors.first.withValues(
                            alpha: 0.3,
                          ),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  plan.title,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.medium.copyWith(
                    color: isSelected
                        ? Colors.white
                        : theme.colorScheme.onSurface.withValues(alpha: 0.65),
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                    fontSize: 12 * scale,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
