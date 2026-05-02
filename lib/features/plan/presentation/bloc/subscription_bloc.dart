import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
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
    on<PurchasePackageEvent>(_onPurchasePackage);
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
      emit(
        state.copyWith(
          offerings: offerings,
          status: SubscriptionStatus.success,
        ),
      );
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
      final snapshot = await subscriptionService.syncWithBackend();
      emit(
        state.copyWith(
          currentTier: snapshot.tier,
          isPremium: snapshot.isPremium,
        ),
      );
    } catch (_) {
      try {
        final snapshot = await subscriptionService.getBackendStatus();
        emit(
          state.copyWith(
            currentTier: snapshot.tier,
            isPremium: snapshot.isPremium,
          ),
        );
      } catch (_) {}
    }
  }

  Future<void> _onCustomerInfoUpdated(
    _CustomerInfoUpdatedEvent event,
    Emitter<SubscriptionState> emit,
  ) async {
    try {
      final snapshot = await subscriptionService.syncWithBackend(
        customerInfo: event.customerInfo,
      );
      emit(
        state.copyWith(
          currentTier: snapshot.tier,
          isPremium: snapshot.isPremium,
        ),
      );
    } catch (_) {
      // CustomerInfo listener is best-effort; explicit purchase/restore flows
      // surface sync errors to the UI.
    }
  }

  Future<void> _onRestorePurchases(
    RestorePurchasesEvent event,
    Emitter<SubscriptionState> emit,
  ) async {
    emit(state.copyWith(purchaseStatus: PurchaseStatus.loading));
    try {
      final customerInfo = await subscriptionService.restorePurchases();
      final snapshot = await subscriptionService.syncWithBackend(
        customerInfo: customerInfo,
      );
      final hadActiveSub = snapshot.isPremium;

      if (hadActiveSub) {
        emit(
          state.copyWith(
            purchaseStatus: PurchaseStatus.success,
            currentTier: snapshot.tier,
            isPremium: true,
            successMessage: 'Abonelik başarıyla geri yüklendi! ✅',
          ),
        );
      } else {
        emit(
          state.copyWith(
            purchaseStatus: PurchaseStatus.failure,
            errorMessage: 'Geri yüklenecek aktif abonelik bulunamadı.',
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          purchaseStatus: PurchaseStatus.failure,
          errorMessage: 'Geri yükleme hatası: $e',
        ),
      );
    }
  }

  Future<void> _onPurchasePackage(
    PurchasePackageEvent event,
    Emitter<SubscriptionState> emit,
  ) async {
    emit(state.copyWith(purchaseStatus: PurchaseStatus.loading));
    try {
      final result = await subscriptionService.purchasePackage(event.package);
      final snapshot = await subscriptionService.syncWithBackend(
        customerInfo: result.customerInfo,
      );

      emit(
        state.copyWith(
          purchaseStatus: PurchaseStatus.success,
          currentTier: snapshot.tier,
          isPremium: snapshot.isPremium,
          successMessage: 'Abonelik başarıyla tamamlandı',
        ),
      );
    } on PlatformException catch (e) {
      final code = PurchasesErrorHelper.getErrorCode(e);
      if (code == PurchasesErrorCode.purchaseCancelledError) {
        emit(state.copyWith(purchaseStatus: PurchaseStatus.initial));
        return;
      }
      emit(
        state.copyWith(
          purchaseStatus: PurchaseStatus.failure,
          errorMessage: 'Satın alma hatası: ${e.message ?? e.code}',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          purchaseStatus: PurchaseStatus.failure,
          errorMessage: 'Satın alma eşitlemesi başarısız: $e',
        ),
      );
    }
  }

  Future<void> _onGetPlans(
    GetSubscriptionPlansEvent event,
    Emitter<SubscriptionState> emit,
  ) async {
    emit(state.copyWith(status: SubscriptionStatus.loading));
    final result = await getPlans(NoParams());
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: SubscriptionStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (plans) => emit(
        state.copyWith(status: SubscriptionStatus.success, plans: plans),
      ),
    );
  }

  Future<void> _onSubscribe(
    SubscribeToPlanEvent event,
    Emitter<SubscriptionState> emit,
  ) async {
    emit(state.copyWith(purchaseStatus: PurchaseStatus.loading));
    final result = await subscribe(
      SubscribeParams(
        planId: event.planId,
        paymentProvider: event.paymentProvider,
        transactionId: event.transactionId,
      ),
    );

    await result.fold<Future<void>>(
      (failure) async => emit(
        state.copyWith(
          purchaseStatus: PurchaseStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (_) async {
        final snapshot = await subscriptionService.syncWithBackend();
        emit(
          state.copyWith(
            purchaseStatus: PurchaseStatus.success,
            currentTier: snapshot.tier,
            isPremium: snapshot.isPremium,
            successMessage: 'Abonelik başarıyla tamamlandı',
          ),
        );
      },
    );
  }

  @override
  Future<void> close() {
    _customerInfoSub.cancel();
    return super.close();
  }
}
