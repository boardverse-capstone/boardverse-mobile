import 'package:flutter/material.dart';

/// Custom painter for the [AnimatedGradientBorder] — sweeps a 4-stop gradient
/// around the rounded rectangle border, creating the continuously rotating
/// "alive" effect.
class GradientBorderPainter extends CustomPainter {
  final double angle;
  final double strokeWidth;
  final double radius;
  final List<Color> colors;

  GradientBorderPainter({
    required this.angle,
    required this.strokeWidth,
    required this.radius,
    required this.colors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));

    final shader = SweepGradient(
      startAngle: angle,
      endAngle: angle + 2 * 3.14159,
      colors: colors,
      tileMode: TileMode.clamp,
    ).createShader(rect);

    final paint = Paint()
      ..shader = shader
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawRRect(rrect.deflate(strokeWidth / 2), paint);
  }

  @override
  bool shouldRepaint(covariant GradientBorderPainter old) =>
      old.angle != angle;
}