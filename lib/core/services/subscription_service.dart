import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';
import 'package:helmove/core/enums/user_tier.dart';

abstract class SubscriptionService {
  Stream<CustomerInfo> get customerInfoStream;
  Future<void> initialize();
  Future<CustomerInfo> logIn(String userId);
  Future<void> logOut();
  Future<bool> isPremium();
  Future<UserTier> getTier();
  Future<CustomerInfo> restorePurchases();
  Future<Offerings> getOfferings();
  Future<PaywallResult> presentPaywall({String? offeringId});
  Future<void> presentCustomerCenter();
  Future<void> syncWithBackend({UserTier? tier, DateTime? expirationDate});
  Future<void> dispose();
}

class SubscriptionServiceImpl implements SubscriptionService {
  final Dio _dio;
  SubscriptionServiceImpl(this._dio);

  // ─── Entitlement IDs (must match RevenueCat dashboard) ─────────────────────
  static const String proEntitlementId = 'pro_features';
  static const String plusEntitlementId = 'plus_features';

  // ─── API Keys — replace with your dashboard keys before release ─────────────
  // Dashboard → Project Settings → API Keys → Public SDK key (iOS / Android)
  static const String _iosApiKey = 'appl_sloAXUFRFHUdqLauCxFmXaGFJuc';
  static const String _androidApiKey = 'goog_CyoKcODkqVPfWuGIQhKOHECgsQU';

  // ─── CustomerInfo broadcast stream ──────────────────────────────────────────
  final _customerInfoController = StreamController<CustomerInfo>.broadcast();

  @override
  Stream<CustomerInfo> get customerInfoStream => _customerInfoController.stream;

  @override
  Future<void> initialize() async {
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        if (kDebugMode) await Purchases.setLogLevel(LogLevel.debug);

        final apiKey = Platform.isIOS ? _iosApiKey : _androidApiKey;
        final configuration = PurchasesConfiguration(apiKey);
        await Purchases.configure(configuration);

        // Push every CustomerInfo change into the broadcast stream so that
        // any live SubscriptionBloc instance reacts automatically.
        Purchases.addCustomerInfoUpdateListener((CustomerInfo info) {
          if (!_customerInfoController.isClosed) {
            _customerInfoController.add(info);
          }
        });

        debugPrint('✅ RevenueCat initialized');
      }
    } catch (e) {
      debugPrint('❌ RevenueCat initialization failed: $e');
    }
  }

  @override
  Future<CustomerInfo> logIn(String userId) async {
    final result = await Purchases.logIn(userId);
    return result.customerInfo;
  }

  @override
  Future<void> logOut() async {
    await Purchases.logOut();
  }

  @override
  Future<bool> isPremium() async {
    final tier = await getTier();
    return tier != UserTier.free;
  }

  @override
  Future<UserTier> getTier() async {
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      return _tierFromCustomerInfo(customerInfo);
    } catch (e) {
      debugPrint('Error checking user tier: $e');
      return UserTier.free;
    }
  }

  @override
  Future<CustomerInfo> restorePurchases() async {
    return await Purchases.restorePurchases();
  }

  @override
  Future<Offerings> getOfferings() async {
    return await Purchases.getOfferings();
  }

  @override
  Future<PaywallResult> presentPaywall({String? offeringId}) async {
    try {
      if (offeringId != null) {
        final offerings = await Purchases.getOfferings();
        final specific = offerings.getOffering(offeringId);
        if (specific != null) {
          return await RevenueCatUI.presentPaywall(offering: specific);
        }
      }
      return await RevenueCatUI.presentPaywall();
    } catch (e) {
      debugPrint('Paywall presentation failed: $e');
      return PaywallResult.error;
    }
  }

  @override
  Future<void> presentCustomerCenter() async {
    try {
      await RevenueCatUI.presentCustomerCenter();
    } catch (e) {
      debugPrint('Customer Center error: $e');
    }
  }

  @override
  Future<void> syncWithBackend({UserTier? tier, DateTime? expirationDate}) async {
    try {
      final currentTier = tier ?? await getTier();

      DateTime? finalExpirationDate = expirationDate;
      if (finalExpirationDate == null && currentTier != UserTier.free) {
        final customerInfo = await Purchases.getCustomerInfo();
        final activeEntitlement = customerInfo.entitlements.active.values.isNotEmpty
            ? customerInfo.entitlements.active.values.first
            : null;
        if (activeEntitlement?.expirationDate != null) {
          finalExpirationDate = DateTime.parse(activeEntitlement!.expirationDate!);
        }
      }

      await _dio.post('/api/subscription/sync', data: {
        'tier': currentTier.index,
        'expirationDate': finalExpirationDate?.toIso8601String(),
      });

      debugPrint('✅ Subscription synced with backend: ${currentTier.name}');
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 404) {
        debugPrint('⚠️ /api/subscription/sync not found (404) — implement on backend.');
      } else {
        debugPrint('❌ Subscription sync failed: $e');
      }
    }
  }

  @override
  Future<void> dispose() async {
    await _customerInfoController.close();
  }

  // ─── Helpers ────────────────────────────────────────────────────────────────

  static UserTier _tierFromCustomerInfo(CustomerInfo info) {
    if (info.entitlements.active.containsKey(proEntitlementId)) return UserTier.pro;
    if (info.entitlements.active.containsKey(plusEntitlementId)) return UserTier.plus;
    return UserTier.free;
  }
}
