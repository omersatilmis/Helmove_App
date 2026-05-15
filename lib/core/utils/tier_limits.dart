import 'package:helmove/core/enums/user_tier.dart';

class TierLimits {
  TierLimits._();

  static const int _freeMotorcycleLimit = 1;
  static const int _plusMotorcycleLimit = 5;
  static const int _proMotorcycleLimit = 99;

  static int motorcycleLimit(UserTier tier) => switch (tier) {
    UserTier.free => _freeMotorcycleLimit,
    UserTier.plus => _plusMotorcycleLimit,
    UserTier.pro => _proMotorcycleLimit,
  };

  static bool canAddMotorcycle(UserTier tier, int currentCount) =>
      currentCount < motorcycleLimit(tier);

  static bool canUseVoiceIntercom(UserTier tier) => tier.isPro;

  static bool canSendSos(UserTier tier) => tier.isPlus;

  static bool canShareLiveLocation(UserTier tier) => tier.isPlus;
}
