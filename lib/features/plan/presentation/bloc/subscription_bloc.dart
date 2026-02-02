import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/usecases/get_plans_usecase.dart';
import '../../domain/usecases/subscribe_usecase.dart';
import 'subscription_event.dart';
import 'subscription_state.dart';

class SubscriptionBloc extends Bloc<SubscriptionEvent, SubscriptionState> {
  final GetPlansUseCase getPlans;
  final SubscribeUseCase subscribe;

  SubscriptionBloc({required this.getPlans, required this.subscribe})
    : super(const SubscriptionState()) {
    on<GetSubscriptionPlansEvent>(_onGetPlans);
    on<SubscribeToPlanEvent>(_onSubscribe);
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
      (_) => emit(
        state.copyWith(
          purchaseStatus: PurchaseStatus.success,
          successMessage: 'Abonelik başarıyla tamamlandı',
        ),
      ),
    );
  }
}
