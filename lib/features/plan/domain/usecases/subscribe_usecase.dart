import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/subscription_repository.dart';

class SubscribeUseCase implements UseCase<void, SubscribeParams> {
  final SubscriptionRepository repository;

  SubscribeUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(SubscribeParams params) async {
    return await repository.subscribe(
      params.planId,
      params.paymentProvider,
      params.transactionId,
    );
  }
}

class SubscribeParams extends Equatable {
  final int planId;
  final String paymentProvider;
  final String transactionId;

  const SubscribeParams({
    required this.planId,
    required this.paymentProvider,
    required this.transactionId,
  });

  @override
  List<Object?> get props => [planId, paymentProvider, transactionId];
}
