import 'package:moto_comm_app_1/features/plan/domain/entities/subscription_plan_entity.dart';
import 'dart:convert';

class SubscriptionPlanModel extends SubscriptionPlanEntity {
  const SubscriptionPlanModel({
    required super.id,
    required super.name,
    required super.code,
    required super.price,
    required super.currency,
    required super.description,
    required super.fullDescription,
    required super.features,
    required super.durationDays,
    required super.isActive,
    required super.isRecommended,
  });

  factory SubscriptionPlanModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlanModel(
      id: json['id'] as int,
      name: json['name'] as String,
      code: json['code'] as String,
      price: (json['price'] as num).toDouble(),
      currency: json['currency'] as String,
      description: json['description'] as String,
      fullDescription: json['fullDescription'] as String,
      features: (jsonDecode(json['featuresJson'] as String) as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      durationDays: json['durationDays'] as int,
      isActive: json['isActive'] as bool,
      isRecommended: json['isRecommended'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'price': price,
      'currency': currency,
      'description': description,
      'fullDescription': fullDescription,
      'featuresJson': jsonEncode(features),
      'durationDays': durationDays,
      'isActive': isActive,
      'isRecommended': isRecommended,
    };
  }
}
