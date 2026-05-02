import 'package:helmove/core/enums/user_tier.dart';

class SubscriptionProducts {
  static const String plusMonthly1 = 'plus_monthly_1';
  static const String plusMonthly6 = 'plus_monthly_6';
  static const String plusYearly1 = 'plus_yearly_1';
  static const String proMonthly1 = 'pro_monthly_1';
  static const String proMonthly6 = 'pro_monthly_6';
  static const String proYearly1 = 'pro_yearly_1';

  static const List<String> plusProductIds = [
    plusMonthly1,
    plusMonthly6,
    plusYearly1,
  ];

  static const List<String> proProductIds = [
    proMonthly1,
    proMonthly6,
    proYearly1,
  ];

  static const List<String> paidProductIds = [
    ...plusProductIds,
    ...proProductIds,
  ];

  static const List<String> displayOrder = [
    plusMonthly1,
    plusMonthly6,
    plusYearly1,
    proMonthly1,
    proMonthly6,
    proYearly1,
  ];

  static bool isKnownProductId(String productId) {
    return paidProductIds.contains(productId);
  }

  static UserTier tierForProductId(String productId) {
    if (proProductIds.contains(productId)) return UserTier.pro;
    if (plusProductIds.contains(productId)) return UserTier.plus;
    return UserTier.free;
  }

  static String titleForProductId(String productId) {
    return switch (productId) {
      plusMonthly1 => 'Plus Aylık',
      plusMonthly6 => 'Plus 6 Aylık',
      plusYearly1 => 'Plus Yıllık',
      proMonthly1 => 'Pro Aylık',
      proMonthly6 => 'Pro 6 Aylık',
      proYearly1 => 'Pro Yıllık',
      _ => productId,
    };
  }

  static String periodLabelForProductId(String productId) {
    return switch (productId) {
      plusMonthly1 || proMonthly1 => '/ay',
      plusMonthly6 || proMonthly6 => '/6 ay',
      plusYearly1 || proYearly1 => '/yıl',
      _ => '',
    };
  }

  static int sortIndex(String productId) {
    final index = displayOrder.indexOf(productId);
    return index == -1 ? displayOrder.length : index;
  }

  static List<String> entitlementsForProducts(Iterable<String> productIds) {
    final ids = productIds.toSet();
    final entitlements = <String>[];
    if (ids.any(proProductIds.contains)) {
      entitlements.add('pro');
    }
    if (ids.any(plusProductIds.contains)) {
      entitlements.add('plus');
    }
    return entitlements;
  }
}
