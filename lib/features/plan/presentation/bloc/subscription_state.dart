import 'package:equatable/equatable.dart';
import '../../domain/entities/subscription_plan_entity.dart';

enum SubscriptionStatus { initial, loading, success, failure }

enum PurchaseStatus { initial, loading, success, failure }

class SubscriptionState extends Equatable {
  final SubscriptionStatus status;
  final PurchaseStatus purchaseStatus;
  final List<SubscriptionPlanEntity> plans;
  final String? errorMessage;
  final String? successMessage;

  const SubscriptionState({
    this.status = SubscriptionStatus.initial,
    this.purchaseStatus = PurchaseStatus.initial,
    this.plans = const [],
    this.errorMessage,
    this.successMessage,
  });

  SubscriptionState copyWith({
    SubscriptionStatus? status,
    PurchaseStatus? purchaseStatus,
    List<SubscriptionPlanEntity>? plans,
    String? errorMessage,
    String? successMessage,
  }) {
    return SubscriptionState(
      status: status ?? this.status,
      purchaseStatus: purchaseStatus ?? this.purchaseStatus,
      plans: plans ?? this.plans,
      errorMessage: errorMessage ?? this.errorMessage,
      successMessage: successMessage ?? this.successMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    purchaseStatus,
    plans,
    errorMessage,
    successMessage,
  ];
}
