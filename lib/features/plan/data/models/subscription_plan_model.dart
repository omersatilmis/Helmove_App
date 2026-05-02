import 'package:helmove/features/plan/domain/entities/subscription_plan_entity.dart';
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
    super.tier,
    super.tierIndex,
    super.badge,
  });

  factory SubscriptionPlanModel.fromJson(Map<String, dynamic> json) {
    int toInt(dynamic value, [int fallback = 0]) {
      if (value == null) return fallback;
      if (value is int) return value;
      if (value is num) return value.toInt();
      return int.tryParse(value.toString()) ?? fallback;
    }

    double toDouble(dynamic value) {
      if (value == null) return 0;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString()) ?? 0;
    }

    bool toBool(dynamic value, {bool fallback = false}) {
      if (value == null) return fallback;
      if (value is bool) return value;
      if (value is num) return value != 0;
      final normalized = value.toString().trim().toLowerCase();
      if (normalized == 'true' || normalized == '1') return true;
      if (normalized == 'false' || normalized == '0') return false;
      return fallback;
    }

    List<String> parseFeatures(dynamic value) {
      if (value is List) {
        return value.map((e) => e.toString()).toList();
      }
      if (value is String && value.trim().isNotEmpty) {
        try {
          final decoded = jsonDecode(value);
          if (decoded is List) {
            return decoded.map((e) => e.toString()).toList();
          }
        } catch (_) {
          return const [];
        }
      }
      return const [];
    }

    return SubscriptionPlanModel(
      id: toInt(json['id'] ?? json['Id']),
      name: (json['name'] ?? json['Name'] ?? '').toString(),
      code: (json['code'] ?? json['Code'] ?? '').toString(),
      price: toDouble(json['price'] ?? json['Price']),
      currency: (json['currency'] ?? json['Currency'] ?? '').toString(),
      description: (json['description'] ?? json['Description'] ?? '')
          .toString(),
      fullDescription:
          (json['fullDescription'] ?? json['FullDescription'] ?? '').toString(),
      features: parseFeatures(
        json['features'] ??
            json['Features'] ??
            json['featuresJson'] ??
            json['FeaturesJson'],
      ),
      durationDays: toInt(json['durationDays'] ?? json['DurationDays']),
      isActive: toBool(json['isActive'] ?? json['IsActive'], fallback: true),
      isRecommended: toBool(json['isRecommended'] ?? json['IsRecommended']),
      tier: (json['tier'] ?? json['Tier'])?.toString(),
      tierIndex: toInt(json['tierIndex'] ?? json['TierIndex'], -1) < 0
          ? null
          : toInt(json['tierIndex'] ?? json['TierIndex']),
      badge: (json['badge'] ?? json['Badge'])?.toString(),
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
      'tier': tier,
      'tierIndex': tierIndex,
      'badge': badge,
    };
  }
}
