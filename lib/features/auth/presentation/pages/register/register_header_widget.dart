import 'package:flutter/material.dart';
import 'package:moto_comm_app_1/core/widgets/wave_painter.dart';

class RegisterHeaderWidget extends StatelessWidget {
  const RegisterHeaderWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final headerColor = theme.brightness == Brightness.light
        ? theme.colorScheme.secondary
        : theme.colorScheme.surfaceContainerLow;

    return Stack(
      fit: StackFit.expand,
      children: [
        Container(color: headerColor),
        Positioned(
          bottom: -1,
          left: 0,
          right: 0,
          child: SizedBox(
            height: 60,
            child: CustomPaint(
              painter: ConstantWavePainter(color: theme.colorScheme.surface),
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                Text(
                  "Aramıza Katılın",
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                Text(
                  "Sürüş deneyiminizi başlatın.",
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white70,
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
