import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class PlanModel {
  final String title;
  final String price;
  final String period;
  final String description;
  final List<String> features;
  final List<Color> gradientColors;
  final String productId;
  final int tierIndex;
  final String? badge;
  // Non-null when loaded from RevenueCat; null for the free plan.
  final Package? rcPackage;

  PlanModel({
    required this.title,
    required this.price,
    required this.period,
    this.description = '',
    required this.features,
    required this.gradientColors,
    required this.productId,
    this.tierIndex = 0,
    this.badge,
    this.rcPackage,
  });
}
