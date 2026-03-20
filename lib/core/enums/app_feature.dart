import '../enums/user_tier.dart';

enum AppFeature {
  /// Basic voice intercom (everyone)
  voiceIntercom(UserTier.free),

  /// Sending/Sharing routes to the group
  routeSharing(UserTier.plus),

  /// Live in-app navigation rendering (Mapbox)
  inAppNavigation(UserTier.pro),

  /// Advanced analytics/ride history
  advancedStats(UserTier.pro);

  final UserTier minTier;
  const AppFeature(this.minTier);

  /// Checks if the given [tier] has access to this feature.
  bool isAvailableFor(UserTier tier) => tier.meets(minTier);
}
