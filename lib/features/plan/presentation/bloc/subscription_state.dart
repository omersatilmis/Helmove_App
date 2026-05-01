import 'package:equatable/equatable.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:helmove/core/enums/user_tier.dart';
import '../../domain/entities/subscription_plan_entity.dart';

enum SubscriptionStatus { initial, loading, success, failure }

enum PurchaseStatus { initial, loading, success, failure }

class SubscriptionState extends Equatable {
  final SubscriptionStatus status;
  final PurchaseStatus purchaseStatus;
  final List<SubscriptionPlanEntity> plans;
  final Offerings? offerings;
  final UserTier currentTier;
  final bool isPremium;
  final String? errorMessage;
  final String? successMessage;

  const SubscriptionState({
    this.status = SubscriptionStatus.initial,
    this.purchaseStatus = PurchaseStatus.initial,
    this.plans = const [],
    this.offerings,
    this.currentTier = UserTier.free,
    this.isPremium = false,
    this.errorMessage,
    this.successMessage,
  });

  SubscriptionState copyWith({
    SubscriptionStatus? status,
    PurchaseStatus? purchaseStatus,
    List<SubscriptionPlanEntity>? plans,
    Offerings? offerings,
    UserTier? currentTier,
    bool? isPremium,
    String? errorMessage,
    String? successMessage,
  }) {
    return SubscriptionState(
      status: status ?? this.status,
      purchaseStatus: purchaseStatus ?? this.purchaseStatus,
      plans: plans ?? this.plans,
      offerings: offerings ?? this.offerings,
      currentTier: currentTier ?? this.currentTier,
      isPremium: isPremium ?? this.isPremium,
      errorMessage: errorMessage ?? this.errorMessage,
      successMessage: successMessage ?? this.successMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    purchaseStatus,
    plans,
    offerings,
    currentTier,
    isPremium,
    errorMessage,
    successMessage,
  ];
}
