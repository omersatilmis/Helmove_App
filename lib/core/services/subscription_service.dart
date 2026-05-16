import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';
import 'package:helmove/core/constants/subscription_products.dart';
import 'package:helmove/core/enums/user_tier.dart';
import 'package:helmove/core/services/app_session.dart';
import 'package:helmove/features/auth/data/datasources/auth_local_data_source.dart';

class SubscriptionStatusSnapshot {
  final UserTier tier;
  final int tierIndex;
  final bool isPremium;
  final List<String> activeProductIds;
  final Map<String, dynamic>? subscription;

  const SubscriptionStatusSnapshot({
    required this.tier,
    required this.tierIndex,
    required this.isPremium,
    this.activeProductIds = const [],
    this.subscription,
  });

  factory SubscriptionStatusSnapshot.free() {
    return const SubscriptionStatusSnapshot(
      tier: UserTier.free,
      tierIndex: 0,
      isPremium: false,
    );
  }

  factory SubscriptionStatusSnapshot.fromJson(Map<String, dynamic> json) {
    int? toInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is num) return value.toInt();
      return int.tryParse(value.toString());
    }

    bool? toBool(dynamic value) {
      if (value == null) return null;
      if (value is bool) return value;
      if (value is num) return value != 0;
      final normalized = value.toString().trim().toLowerCase();
      if (normalized == 'true' || normalized == '1') return true;
      if (normalized == 'false' || normalized == '0') return false;
      return null;
    }

    List<String> toStringList(dynamic value) {
      if (value is List) {
        return value.map((e) => e.toString()).toList();
      }
      return const [];
    }

    final rawTier =
        (json['tier'] ??
                json['Tier'] ??
                json['premiumTier'] ??
                json['PremiumTier'])
            ?.toString();
    final parsedIndex = toInt(json['tierIndex'] ?? json['TierIndex']);
    final parsedTier = UserTier.fromJson(tier: rawTier, tierIndex: parsedIndex);
    final resolvedIndex = parsedIndex ?? parsedTier.tierIndex;

    return SubscriptionStatusSnapshot(
      tier: parsedTier,
      tierIndex: resolvedIndex,
      isPremium:
          toBool(json['isPremium'] ?? json['IsPremium']) ?? resolvedIndex > 0,
      activeProductIds: toStringList(
        json['activeProductIds'] ??
            json['ActiveProductIds'] ??
            json['activeSubscriptions'] ??
            json['ActiveSubscriptions'],
      ),
      subscription: json['subscription'] is Map
          ? Map<String, dynamic>.from(json['subscription'] as Map)
          : json['Subscription'] is Map
          ? Map<String, dynamic>.from(json['Subscription'] as Map)
          : null,
    );
  }
}

abstract class SubscriptionService {
  Stream<CustomerInfo> get customerInfoStream;
  Future<void> initialize();
  Future<CustomerInfo> getCustomerInfo();
  Future<CustomerInfo> logIn(String userId);
  Future<void> logOut();
  Future<bool> isPremium();
  Future<UserTier> getTier();
  Future<CustomerInfo> restorePurchases();
  Future<Offerings> getOfferings();
  Future<PurchaseResult> purchasePackage(Package package);
  Future<void> presentCustomerCenter();
  Future<SubscriptionStatusSnapshot> getBackendStatus();
  Future<SubscriptionStatusSnapshot> syncWithBackend({
    CustomerInfo? customerInfo,
  });
  Future<void> dispose();
}

class SubscriptionServiceImpl implements SubscriptionService {
  final Dio _dio;
  final AuthLocalDataSource _authLocalDataSource;
  final AppSession _appSession;

  SubscriptionServiceImpl(
    this._dio,
    this._authLocalDataSource,
    this._appSession,
  );

  // ─── Entitlement IDs (must match RevenueCat dashboard) ─────────────────────
  static const String proEntitlementId = 'pro';
  static const String plusEntitlementId = 'plus';

  // ─── API Keys — replace with your dashboard keys before release ─────────────
  // Dashboard → Project Settings → API Keys → Public SDK key (iOS / Android)
  static const String _iosApiKey = 'appl_sloAXUFRFHUdqLauCxFmXaGFJuc';
  static const String _androidApiKey = 'goog_CyoKcODkqVPfWuGIQhKOHECgsQU';

  // ─── CustomerInfo broadcast stream ──────────────────────────────────────────
  final _customerInfoController = StreamController<CustomerInfo>.broadcast();
  bool _isConfigured = false;
  SubscriptionStatusSnapshot _lastStatus = SubscriptionStatusSnapshot.free();

  @override
  Stream<CustomerInfo> get customerInfoStream => _customerInfoController.stream;

  @override
  Future<void> initialize() async {
    try {
      if (_isConfigured) return;
      if (_isStorePlatform) {
        if (kDebugMode) await Purchases.setLogLevel(LogLevel.debug);

        final apiKey = Platform.isIOS ? _iosApiKey : _androidApiKey;
        final configuration = PurchasesConfiguration(apiKey);
        await Purchases.configure(configuration);
        _isConfigured = true;

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
  Future<CustomerInfo> getCustomerInfo() async {
    await _ensureStoreConfigured();
    return Purchases.getCustomerInfo();
  }

  @override
  Future<CustomerInfo> logIn(String userId) async {
    await _ensureStoreConfigured();
    if (userId.trim().isEmpty) {
      throw ArgumentError('RevenueCat appUserID must be the backend user id.');
    }
    final result = await Purchases.logIn(userId);
    return result.customerInfo;
  }

  @override
  Future<void> logOut() async {
    try {
      if (_isStorePlatform) {
        await initialize();
        await Purchases.logOut();
      }
    } catch (e) {
      debugPrint('RevenueCat logout ignored: $e');
    } finally {
      await _cacheStatus(SubscriptionStatusSnapshot.free());
    }
  }

  @override
  Future<bool> isPremium() async {
    final tier = await getTier();
    return tier.isPremium;
  }

  @override
  Future<UserTier> getTier() async {
    try {
      final snapshot = await syncWithBackend();
      return snapshot.tier;
    } catch (e) {
      try {
        final snapshot = await getBackendStatus();
        return snapshot.tier;
      } catch (_) {
        debugPrint('Error checking user tier: $e');
        return _lastStatus.tier;
      }
    }
  }

  @override
  Future<CustomerInfo> restorePurchases() async {
    await _ensureStoreConfigured();
    return await Purchases.restorePurchases();
  }

  @override
  Future<Offerings> getOfferings() async {
    await _ensureStoreConfigured();
    return await Purchases.getOfferings();
  }

  @override
  Future<PurchaseResult> purchasePackage(Package package) async {
    await _ensureStoreConfigured();
    return Purchases.purchase(PurchaseParams.package(package));
  }

  @override
  Future<void> presentCustomerCenter() async {
    try {
      if (!_isStorePlatform) return;
      await _ensureStoreConfigured();
      await RevenueCatUI.presentCustomerCenter();
    } catch (e) {
      debugPrint('Customer Center error: $e');
    }
  }

  @override
  Future<SubscriptionStatusSnapshot> getBackendStatus() async {
    try {
      final response = await _dio.get('/api/subscription/status');
      final snapshot = SubscriptionStatusSnapshot.fromJson(
        _extractResponseMap(response.data),
      );
      await _cacheStatus(snapshot);
      return snapshot;
    } catch (e) {
      debugPrint('❌ Subscription status failed: $e');
      rethrow;
    }
  }

  @override
  Future<SubscriptionStatusSnapshot> syncWithBackend({
    CustomerInfo? customerInfo,
  }) async {
    try {
      final info = customerInfo ?? await getCustomerInfo();
      final activeProductIds =
          info.activeSubscriptions
              .where(SubscriptionProducts.isKnownProductId)
              .toList()
            ..sort((a, b) {
              return SubscriptionProducts.sortIndex(
                a,
              ).compareTo(SubscriptionProducts.sortIndex(b));
            });

      final activeEntitlements = _activeEntitlementIds(info, activeProductIds);

      // En yüksek tierli entitlement'ın bitiş tarihini bul
      final expiresAt = _resolveExpiresAt(info, activeEntitlements);

      final payload = {
        'activeProductIds': activeProductIds,
        'activeEntitlements': activeEntitlements,
        'originalAppUserId': await _currentRevenueCatAppUserId(info),
        if (expiresAt != null) 'expiresAt': expiresAt.toUtc().toIso8601String(),
      };

      final response = await _dio.post('/api/subscription/sync', data: payload);
      debugPrint('📦 Sync raw response [${response.statusCode}]: ${response.data}');
      final snapshot = SubscriptionStatusSnapshot.fromJson(
        _extractResponseMap(response.data),
      );
      await _cacheStatus(snapshot);

      debugPrint(
        '✅ Subscription synced — parsed tier: '
        '${snapshot.tier.name} (index=${snapshot.tierIndex}, isPremium=${snapshot.isPremium})',
      );
      return snapshot;
    } catch (e) {
      debugPrint('❌ Subscription sync failed: $e');
      rethrow;
    }
  }

  @override
  Future<void> dispose() async {
    await _customerInfoController.close();
  }

  // ─── Helpers ────────────────────────────────────────────────────────────────

  static bool get _isStorePlatform => Platform.isAndroid || Platform.isIOS;

  Future<void> _ensureStoreConfigured() async {
    if (!_isStorePlatform) {
      throw UnsupportedError(
        'RevenueCat purchases are only available on iOS and Android.',
      );
    }
    await initialize();
    if (!_isConfigured) {
      throw StateError('RevenueCat is not configured.');
    }
  }

  static Map<String, dynamic> _extractResponseMap(dynamic data) {
    if (data is Map<String, dynamic>) {
      final nested = data['data'] ?? data['Data'];
      if (nested is Map<String, dynamic>) return nested;
      if (nested is Map) return Map<String, dynamic>.from(nested);
      return data;
    }
    if (data is Map) return Map<String, dynamic>.from(data);
    return const {};
  }

  Future<String> _currentRevenueCatAppUserId(CustomerInfo info) async {
    try {
      final appUserId = await Purchases.appUserID;
      if (appUserId.trim().isNotEmpty &&
          !appUserId.startsWith(r'$RCAnonymousID:')) {
        return appUserId;
      }
    } catch (_) {}

    final sessionUserId = _appSession.currentUserId;
    if (sessionUserId != null && sessionUserId > 0) {
      return sessionUserId.toString();
    }

    return info.originalAppUserId;
  }

  static DateTime? _resolveExpiresAt(
    CustomerInfo info,
    List<String> activeEntitlements,
  ) {
    // Pro > Plus önceliği — en yüksek tierli entitlement'ın bitiş tarihi
    final priority = [proEntitlementId, plusEntitlementId];
    for (final id in priority) {
      if (activeEntitlements.contains(id)) {
        final expiryStr = info.entitlements.active[id]?.expirationDate;
        if (expiryStr != null) return DateTime.tryParse(expiryStr);
      }
    }
    return null;
  }

  static List<String> _activeEntitlementIds(
    CustomerInfo info,
    List<String> activeProductIds,
  ) {
    final entitlements = SubscriptionProducts.entitlementsForProducts(
      activeProductIds,
    ).toSet();

    for (final key in info.entitlements.active.keys) {
      final normalized = key.trim().toLowerCase();
      if (normalized == proEntitlementId) {
        entitlements.add(proEntitlementId);
      } else if (normalized == plusEntitlementId) {
        entitlements.add(plusEntitlementId);
      }
    }

    return entitlements.toList()..sort();
  }

  Future<void> _cacheStatus(SubscriptionStatusSnapshot snapshot) async {
    _lastStatus = snapshot;
    await _authLocalDataSource.saveTier(snapshot.tier);

    final currentUser = _appSession.currentUser;
    if (currentUser != null && currentUser.tier != snapshot.tier) {
      _appSession.updateSession(
        currentUserId: currentUser.id,
        currentUser: currentUser.copyWith(tier: snapshot.tier),
        token: currentUser.token,
      );
    }
  }
}
