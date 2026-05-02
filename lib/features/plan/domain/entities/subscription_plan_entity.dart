import 'package:equatable/equatable.dart';

class SubscriptionPlanEntity extends Equatable {
  final int id;
  final String name;
  final String code;
  final double price;
  final String currency;
  final String description;
  final String fullDescription;
  final List<String> features;
  final int durationDays;
  final bool isActive;
  final bool isRecommended;
  final String? tier;
  final int? tierIndex;
  final String? badge;

  const SubscriptionPlanEntity({
    required this.id,
    required this.name,
    required this.code,
    required this.price,
    required this.currency,
    required this.description,
    required this.fullDescription,
    required this.features,
    required this.durationDays,
    required this.isActive,
    required this.isRecommended,
    this.tier,
    this.tierIndex,
    this.badge,
  });

  @override
  List<Object?> get props => [
    id,
    name,
    code,
    price,
    currency,
    description,
    fullDescription,
    features,
    durationDays,
    isActive,
    isRecommended,
    tier,
    tierIndex,
    badge,
  ];
}
