import 'package:equatable/equatable.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

abstract class SubscriptionEvent extends Equatable {
  const SubscriptionEvent();

  @override
  List<Object?> get props => [];
}

class LoadOfferingsEvent extends SubscriptionEvent {
  const LoadOfferingsEvent();
}

class CheckPremiumStatusEvent extends SubscriptionEvent {
  const CheckPremiumStatusEvent();
}

class RestorePurchasesEvent extends SubscriptionEvent {
  const RestorePurchasesEvent();
}

class PurchasePackageEvent extends SubscriptionEvent {
  final Package package;

  const PurchasePackageEvent(this.package);

  @override
  List<Object?> get props => [package.storeProduct.identifier];
}

// Keep for backward compat (e.g. direct backend-side subscribe flow).
class GetSubscriptionPlansEvent extends SubscriptionEvent {
  const GetSubscriptionPlansEvent();
}

class SubscribeToPlanEvent extends SubscriptionEvent {
  final int planId;
  final String paymentProvider;
  final String transactionId;

  const SubscribeToPlanEvent({
    required this.planId,
    required this.paymentProvider,
    required this.transactionId,
  });

  @override
  List<Object?> get props => [planId, paymentProvider, transactionId];
}
