import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class PlanModel {
  final String title;
  final String price;
  final String period;
  final List<String> features;
  final List<Color> gradientColors;
  final String productId;
  // Non-null when offerings were loaded from RevenueCat; null for the free plan.
  final Offering? rcOffering;

  PlanModel({
    required this.title,
    required this.price,
    required this.period,
    required this.features,
    required this.gradientColors,
    required this.productId,
    this.rcOffering,
  });
}
