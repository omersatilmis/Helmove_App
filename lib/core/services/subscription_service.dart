import 'package:helmove/core/enums/user_tier.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'dart:io';

abstract class SubscriptionService {
  Future<void> initialize();
  Future<CustomerInfo> logIn(String userId);
  Future<void> logOut();
  Future<bool> isPremium();
  Future<UserTier> getTier();
  Future<CustomerInfo> restorePurchases();
  Future<Offerings> getOfferings();
  // Artık hangi paywall'u açacağımızı seçebiliyoruz
  Future<PaywallResult> presentPaywall({String? offeringId});
  Future<void> presentCustomerCenter();
  Future<void> syncWithBackend({UserTier? tier, DateTime? expirationDate});
}

class SubscriptionServiceImpl implements SubscriptionService {
  final Dio _dio;
  SubscriptionServiceImpl(this._dio);

  // NOT: Buradaki API Key'i kendi dashboard'undaki gerçek key ile değiştirmeyi unutma reis!
  static const String _apiKey = 'test_IBZaChseBJTxgntkgYBvwSryfbb';

  // Dashboard'da oluşturduğumuz Entitlement ID'leri
  static const String _proEntitlementId = 'pro_features';
  static const String _plusEntitlementId = 'plus_features';

  @override
  Future<void> initialize() async {
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        if (kDebugMode) {
          await Purchases.setLogLevel(LogLevel.debug);
        }
        final configuration = PurchasesConfiguration(_apiKey);
        await Purchases.configure(configuration);
        debugPrint('✅ RevenueCat initialized (Helmove Edition)');
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

      // Önce en üst seviye olan PRO'yu kontrol ediyoruz (Hiyerarşi önemli!)
      if (customerInfo.entitlements.active.containsKey(_proEntitlementId)) {
        return UserTier.pro;
      }

      // PRO yoksa PLUS var mı ona bakıyoruz
      if (customerInfo.entitlements.active.containsKey(_plusEntitlementId)) {
        return UserTier.plus;
      }

      return UserTier.free;
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
        // Belirli bir offering (pro_offering veya plus_offering) istenmişse onu getir
        final offerings = await Purchases.getOfferings();
        final specificOffering = offerings.getOffering(offeringId);

        if (specificOffering != null) {
          return await RevenueCatUI.presentPaywall(offering: specificOffering);
        }
      }
      // offeringId null ise veya bulunamadıysa varsayılan (default) paywall'u açar
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
      debugPrint('Customer Center not supported or error: $e');
    }
  }

  @override
  Future<void> syncWithBackend({UserTier? tier, DateTime? expirationDate}) async {
    try {
      final currentTier = tier ?? await getTier();
      
      // Eğer expirationDate verilmemişse RevenueCat'ten en güncelini çekmeye çalışalım
      DateTime? finalExpirationDate = expirationDate;
      if (finalExpirationDate == null && currentTier != UserTier.free) {
        final customerInfo = await Purchases.getCustomerInfo();
        // Aktif olan ilk entitlement'ın bitiş tarihini alalım
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
      
      debugPrint('✅ Subscription state synced with backend: ${currentTier.name}');
    } catch (e) {
      debugPrint('❌ Subscription sync failed: $e');
    }
  }
}
