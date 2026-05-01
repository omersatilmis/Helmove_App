import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:helmove/core/enums/user_tier.dart';
import '../../../../core/services/subscription_service.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/usecases/get_plans_usecase.dart';
import '../../domain/usecases/subscribe_usecase.dart';
import 'subscription_event.dart';
import 'subscription_state.dart';

// Internal event — not exposed outside this file.
class _CustomerInfoUpdatedEvent extends SubscriptionEvent {
  final CustomerInfo customerInfo;
  const _CustomerInfoUpdatedEvent(this.customerInfo);

  @override
  List<Object?> get props => [customerInfo.originalAppUserId];
}

class SubscriptionBloc extends Bloc<SubscriptionEvent, SubscriptionState> {
  final GetPlansUseCase getPlans;
  final SubscribeUseCase subscribe;
  final SubscriptionService subscriptionService;

  late final StreamSubscription<CustomerInfo> _customerInfoSub;

  SubscriptionBloc({
    required this.getPlans,
    required this.subscribe,
    required this.subscriptionService,
  }) : super(const SubscriptionState()) {
    on<LoadOfferingsEvent>(_onLoadOfferings);
    on<CheckPremiumStatusEvent>(_onCheckPremiumStatus);
    on<RestorePurchasesEvent>(_onRestorePurchases);
    on<GetSubscriptionPlansEvent>(_onGetPlans);
    on<SubscribeToPlanEvent>(_onSubscribe);
    on<_CustomerInfoUpdatedEvent>(_onCustomerInfoUpdated);

    // Whenever RevenueCat notifies a change (purchase, restore, expiry),
    // fire an internal event so the bloc stays in sync automatically.
    _customerInfoSub = subscriptionService.customerInfoStream.listen((info) {
      if (!isClosed) add(_CustomerInfoUpdatedEvent(info));
    });
  }

  // ─── Handlers ────────────────────────────────────────────────────────────────

  Future<void> _onLoadOfferings(
    LoadOfferingsEvent event,
    Emitter<SubscriptionState> emit,
  ) async {
    try {
      final offerings = await subscriptionService.getOfferings();
      emit(state.copyWith(offerings: offerings, status: SubscriptionStatus.success));
    } catch (e) {
      // Non-fatal: plan page falls back to static data when offerings == null.
      emit(state.copyWith(status: SubscriptionStatus.failure));
    }
  }

  Future<void> _onCheckPremiumStatus(
    CheckPremiumStatusEvent event,
    Emitter<SubscriptionState> emit,
  ) async {
    try {
      final tier = await subscriptionService.getTier();
      emit(state.copyWith(currentTier: tier, isPremium: tier != UserTier.free));
    } catch (_) {}
  }

  Future<void> _onCustomerInfoUpdated(
    _CustomerInfoUpdatedEvent event,
    Emitter<SubscriptionState> emit,
  ) async {
    final tier = _tierFrom(event.customerInfo);
    // Silently sync backend; don't surface errors to UI here.
    subscriptionService.syncWithBackend(tier: tier);
    emit(state.copyWith(currentTier: tier, isPremium: tier != UserTier.free));
  }

  Future<void> _onRestorePurchases(
    RestorePurchasesEvent event,
    Emitter<SubscriptionState> emit,
  ) async {
    emit(state.copyWith(purchaseStatus: PurchaseStatus.loading));
    try {
      final customerInfo = await subscriptionService.restorePurchases();
      final tier = _tierFrom(customerInfo);
      final hadActiveSub = tier != UserTier.free;

      subscriptionService.syncWithBackend(tier: tier);

      if (hadActiveSub) {
        emit(state.copyWith(
          purchaseStatus: PurchaseStatus.success,
          currentTier: tier,
          isPremium: true,
          successMessage: 'Abonelik başarıyla geri yüklendi! ✅',
        ));
      } else {
        emit(state.copyWith(
          purchaseStatus: PurchaseStatus.failure,
          errorMessage: 'Geri yüklenecek aktif abonelik bulunamadı.',
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        purchaseStatus: PurchaseStatus.failure,
        errorMessage: 'Geri yükleme hatası: $e',
      ));
    }
  }

  Future<void> _onGetPlans(
    GetSubscriptionPlansEvent event,
    Emitter<SubscriptionState> emit,
  ) async {
    emit(state.copyWith(status: SubscriptionStatus.loading));
    final result = await getPlans(NoParams());
    result.fold(
      (failure) => emit(state.copyWith(
        status: SubscriptionStatus.failure,
        errorMessage: failure.message,
      )),
      (plans) => emit(state.copyWith(
        status: SubscriptionStatus.success,
        plans: plans,
      )),
    );
  }

  Future<void> _onSubscribe(
    SubscribeToPlanEvent event,
    Emitter<SubscriptionState> emit,
  ) async {
    emit(state.copyWith(purchaseStatus: PurchaseStatus.loading));
    final result = await subscribe(SubscribeParams(
      planId: event.planId,
      paymentProvider: event.paymentProvider,
      transactionId: event.transactionId,
    ));

    result.fold(
      (failure) => emit(state.copyWith(
        purchaseStatus: PurchaseStatus.failure,
        errorMessage: failure.message,
      )),
      (_) {
        subscriptionService.syncWithBackend();
        emit(state.copyWith(
          purchaseStatus: PurchaseStatus.success,
          successMessage: 'Abonelik başarıyla tamamlandı',
        ));
      },
    );
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────────

  static UserTier _tierFrom(CustomerInfo info) {
    if (info.entitlements.active.containsKey(SubscriptionServiceImpl.proEntitlementId)) {
      return UserTier.pro;
    }
    if (info.entitlements.active.containsKey(SubscriptionServiceImpl.plusEntitlementId)) {
      return UserTier.plus;
    }
    return UserTier.free;
  }

  @override
  Future<void> close() {
    _customerInfoSub.cancel();
    return super.close();
  }
}
