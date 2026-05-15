import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:helmove/core/enums/user_tier.dart';
import 'package:helmove/core/theme/text_styles.dart';

class TierUpsellSheet extends StatelessWidget {
  final UserTier requiredTier;
  final String featureTitle;
  final String featureDescription;
  final IconData icon;

  const TierUpsellSheet({
    super.key,
    required this.requiredTier,
    required this.featureTitle,
    required this.featureDescription,
    this.icon = Icons.lock_outline,
  });

  static Future<void> show(
    BuildContext context, {
    required UserTier requiredTier,
    required String featureTitle,
    required String featureDescription,
    IconData icon = Icons.lock_outline,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TierUpsellSheet(
        requiredTier: requiredTier,
        featureTitle: featureTitle,
        featureDescription: featureDescription,
        icon: icon,
      ),
    );
  }

  String get _tierLabel => switch (requiredTier) {
    UserTier.plus => 'Plus',
    UserTier.pro => 'Pro',
    _ => '',
  };

  Color _tierColor() => switch (requiredTier) {
    UserTier.plus => const Color(0xFF2193b0),
    UserTier.pro => const Color(0xFFf12711),
    _ => const Color(0xFF606c88),
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tierColor = _tierColor();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
          ),
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: tierColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: tierColor, size: 32),
              ),
              const SizedBox(height: 16),
              Text(
                'HELMOVE $_tierLabel',
                style: AppTextStyles.bodySmall.copyWith(
                  color: tierColor,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                featureTitle,
                style: AppTextStyles.h3,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                featureDescription,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    context.push('/plan');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: tierColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    "$_tierLabel'a Yükselt",
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Şimdi Değil',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
