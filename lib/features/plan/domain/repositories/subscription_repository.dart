import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/subscription_plan_entity.dart';

abstract class SubscriptionRepository {
  Future<Either<Failure, List<SubscriptionPlanEntity>>> getPlans();
  Future<Either<Failure, void>> subscribe(
    int planId,
    String paymentProvider,
    String transactionId,
  );
}
