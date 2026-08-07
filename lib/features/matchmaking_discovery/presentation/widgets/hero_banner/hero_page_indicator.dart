import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';

/// Page indicator dots có animation.
class HeroPageIndicator extends StatelessWidget {
  final int count;
  final int current;
  final ValueChanged<int> onDotTapped;

  const HeroPageIndicator({
    super.key,
    required this.count,
    required this.current,
    required this.onDotTapped,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final isActive = index == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
          width: isActive ? AppSpacing.xl : AppSpacing.xs,
          height: AppSpacing.xs - 2,
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.primary
                : AppColors.primary.withValues(alpha: 0.3),
            borderRadius: AppRadius.radiusFullAll,
          ),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onDotTapped(index),
          ),
        );
      }),
    );
  }
}
