import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import 'gradient_border_painter.dart';

/// Animated gradient border — viền gradient chuyển động liên tục tạo cảm
/// giác "alive" cho hero banner. Chỉ dùng cho banner lớn để tránh rối mắt.
class AnimatedGradientBorder extends StatefulWidget {
  final Widget child;
  final BorderRadius borderRadius;

  const AnimatedGradientBorder({
    super.key,
    required this.child,
    required this.borderRadius,
  });

  @override
  State<AnimatedGradientBorder> createState() =>
      _AnimatedGradientBorderState();
}

class _AnimatedGradientBorderState extends State<AnimatedGradientBorder>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  static const double _borderWidth = 2;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        return CustomPaint(
          painter: GradientBorderPainter(
            angle: _ctrl.value * 2 * 3.14159,
            strokeWidth: _borderWidth,
            radius: widget.borderRadius.topLeft.x,
            colors: const [
              AppColors.primary,
              AppColors.accent,
              AppColors.warning,
              AppColors.primary,
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(_borderWidth),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(
                widget.borderRadius.topLeft.x - _borderWidth,
              ),
              child: child,
            ),
          ),
        );
      },
      child: widget.child,
    );
  }
}
