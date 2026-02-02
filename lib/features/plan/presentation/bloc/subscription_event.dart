import 'package:equatable/equatable.dart';

abstract class SubscriptionEvent extends Equatable {
  const SubscriptionEvent();

  @override
  List<Object?> get props => [];
}

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
