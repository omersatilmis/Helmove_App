import 'package:flutter/material.dart';
import 'package:moto_comm_app_1/core/widgets/wave_painter.dart';

class AuthHeaderWidget extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData? icon;

  const AuthHeaderWidget({
    super.key,
    required this.title,
    required this.subtitle,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final headerColor = theme.brightness == Brightness.light
        ? theme.colorScheme.primary
        : theme.colorScheme.surfaceContainerLow;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Arka Plan Rengi
        Container(color: headerColor),

        // Dalga Efekti
        Positioned(
          bottom: -1, // Piksel boşluğunu önlemek için
          left: 0,
          right: 0,
          child: SizedBox(
            height: 60,
            child: CustomPaint(
              painter: ConstantWavePainter(color: theme.colorScheme.surface),
            ),
          ),
        ),

        // İçerik (İkon ve Yazılar)
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (icon != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(icon, size: 40, color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                ] else ...[
                  const SizedBox(height: 20),
                ],
                Text(
                  title,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
