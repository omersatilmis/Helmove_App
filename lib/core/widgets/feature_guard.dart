import 'package:flutter/material.dart';
import '../enums/app_feature.dart';
import '../enums/user_tier.dart';

/// A wrapper widget that checks if a specific [feature] is available for the 
/// current user's [tier].
/// 
/// If the feature is locked, [onLocked] is called when the user attempts 
/// to interact with the [child].
class FeatureGuard extends StatelessWidget {
  final AppFeature feature;
  final UserTier tier;
  final Widget child;
  final VoidCallback? onLocked;
  final bool showLockIcon;

  const FeatureGuard({
    super.key,
    required this.feature,
    required this.tier,
    required this.child,
    this.onLocked,
    this.showLockIcon = true,
  });

  bool get _isAvailable => feature.isAvailableFor(tier);

  @override
  Widget build(BuildContext context) {
    if (_isAvailable) {
      return child;
    }

    return GestureDetector(
      onTap: onLocked,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Opacity(
            opacity: 0.5,
            child: AbsorbPointer(child: child),
          ),
          if (showLockIcon)
            const Icon(
              Icons.lock_outline_rounded,
              color: Colors.amber,
              size: 20,
            ),
        ],
      ),
    );
  }
}
