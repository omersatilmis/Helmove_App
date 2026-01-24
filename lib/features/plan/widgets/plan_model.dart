import 'package:flutter/material.dart';

class PlanModel {
  final String title;
  final String price;
  final String period; // "/ay" veya "/yıl"
  final List<String> features;
  final List<Color> gradientColors;
  final String productId; // Google Play Product ID (Gelecek için)

  PlanModel({
    required this.title,
    required this.price,
    required this.period,
    required this.features,
    required this.gradientColors,
    required this.productId,
  });
}