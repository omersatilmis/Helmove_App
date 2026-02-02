import 'package:dartz/dartz.dart';
import '../../../../core/error/app_exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/subscription_plan_entity.dart';
import '../../domain/repositories/subscription_repository.dart';
import '../datasources/subscription_remote_data_source.dart';

class SubscriptionRepositoryImpl implements SubscriptionRepository {
  final SubscriptionRemoteDataSource remoteDataSource;

  SubscriptionRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<SubscriptionPlanEntity>>> getPlans() async {
    try {
      final plans = await remoteDataSource.getPlans();
      return Right(plans);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> subscribe(
    int planId,
    String paymentProvider,
    String transactionId,
  ) async {
    try {
      return Right(
        await remoteDataSource.subscribe(
          planId,
          paymentProvider,
          transactionId,
        ),
      );
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }
}
