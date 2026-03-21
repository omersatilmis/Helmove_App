import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/subscription_service.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/usecases/get_plans_usecase.dart';
import '../../domain/usecases/subscribe_usecase.dart';
import 'subscription_event.dart';
import 'subscription_state.dart';

class SubscriptionBloc extends Bloc<SubscriptionEvent, SubscriptionState> {
  final GetPlansUseCase getPlans;
  final SubscribeUseCase subscribe;
  final SubscriptionService subscriptionService;

  SubscriptionBloc({
    required this.getPlans,
    required this.subscribe,
    required this.subscriptionService,
  }) : super(const SubscriptionState()) {
    on<GetSubscriptionPlansEvent>(_onGetPlans);
    on<SubscribeToPlanEvent>(_onSubscribe);
    on<RestorePurchasesEvent>(_onRestorePurchases);
    on<CheckPremiumStatusEvent>(_onCheckPremiumStatus);
  }

  Future<void> _onCheckPremiumStatus(
    CheckPremiumStatusEvent event,
    Emitter<SubscriptionState> emit,
  ) async {
    try {
      final isPremium = await subscriptionService.isPremium();
      emit(state.copyWith(isPremium: isPremium));
    } catch (e) {
      // Handle error if needed
    }
  }

  Future<void> _onRestorePurchases(
    RestorePurchasesEvent event,
    Emitter<SubscriptionState> emit,
  ) async {
    emit(state.copyWith(purchaseStatus: PurchaseStatus.loading));
    try {
      final customerInfo = await subscriptionService.restorePurchases();
      final isPremium =
          customerInfo.entitlements.active.containsKey('Helmove Premium');
      if (isPremium) {
        subscriptionService.syncWithBackend();
        emit(
          state.copyWith(
            purchaseStatus: PurchaseStatus.success,
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

    result.fold(
      (failure) => emit(
        state.copyWith(
          purchaseStatus: PurchaseStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (_) {
        subscriptionService.syncWithBackend();
        emit(
          state.copyWith(
            purchaseStatus: PurchaseStatus.success,
            successMessage: 'Abonelik başarıyla tamamlandı',
          ),
        );
      },
    );
  }
}
