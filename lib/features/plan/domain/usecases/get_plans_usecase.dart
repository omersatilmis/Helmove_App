import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/subscription_plan_entity.dart';
import '../repositories/subscription_repository.dart';

class GetPlansUseCase
    implements UseCase<List<SubscriptionPlanEntity>, NoParams> {
  final SubscriptionRepository repository;

  GetPlansUseCase(this.repository);

  @override
  Future<Either<Failure, List<SubscriptionPlanEntity>>> call(
    NoParams params,
  ) async {
    return await repository.getPlans();
  }
}
