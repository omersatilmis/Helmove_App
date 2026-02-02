import 'package:dio/dio.dart';
import '../../../../core/error/app_exceptions.dart';
import '../../../../core/error/error_handler.dart';
import '../models/subscription_plan_model.dart';

abstract class SubscriptionRemoteDataSource {
  Future<List<SubscriptionPlanModel>> getPlans();
  Future<void> subscribe(
    int planId,
    String paymentProvider,
    String transactionId,
  );
}

class SubscriptionRemoteDataSourceImpl implements SubscriptionRemoteDataSource {
  final Dio client;

  SubscriptionRemoteDataSourceImpl({required this.client});

  @override
  Future<List<SubscriptionPlanModel>> getPlans() async {
    try {
      final response = await client.get('/api/subscription/plans');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data
            .map((json) => SubscriptionPlanModel.fromJson(json))
            .toList();
      } else {
        throw ServerException('Planlar yüklenemedi');
      }
    } on DioException catch (e) {
      ErrorHandler.handleApiError(e);
    }
  }

  @override
  Future<void> subscribe(
    int planId,
    String paymentProvider,
    String transactionId,
  ) async {
    try {
      final response = await client.post(
        '/api/subscription/subscribe',
        data: {
          'planId': planId,
          'paymentProvider': paymentProvider,
          'transactionId': transactionId,
        },
      );

      if (response.statusCode != 200) {
        throw ServerException('Abonelik işlemi başarısız');
      }
    } on DioException catch (e) {
      ErrorHandler.handleApiError(e);
    }
  }
}
