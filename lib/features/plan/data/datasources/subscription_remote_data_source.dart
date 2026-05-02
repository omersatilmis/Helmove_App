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
        final rawData = response.data;
        final List<dynamic> data = rawData is List
            ? rawData
            : rawData is Map && rawData['data'] is List
            ? rawData['data'] as List<dynamic>
            : rawData is Map && rawData['Data'] is List
            ? rawData['Data'] as List<dynamic>
            : const [];
        return data
            .whereType<Map>()
            .map(
              (json) => SubscriptionPlanModel.fromJson(
                Map<String, dynamic>.from(json),
              ),
            )
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
    throw ServerException(
      'Satın alma RevenueCat ve App Store üzerinden yapılmalı.',
    );
  }
}
