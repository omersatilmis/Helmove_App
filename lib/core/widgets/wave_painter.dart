import 'package:flutter/material.dart';

class ConstantWavePainter extends CustomPainter {
  final Color color;

  const ConstantWavePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final path = Path();
    final w = size.width;
    final h = size.height;

    path.moveTo(0, h * 0.75);
    path.cubicTo(w * 0.28, h * 0.5, w * 0.72, h, w, 0);
    path.lineTo(w, h);
    path.lineTo(0, h);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant ConstantWavePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
