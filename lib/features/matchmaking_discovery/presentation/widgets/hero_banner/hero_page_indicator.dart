import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';

/// Neo-brutalism Page indicator dots.
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
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onDotTapped(index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: isActive ? 24 : 10,
            height: 10,
            decoration: BoxDecoration(
              color: isActive
                  ? AppColors.primary
                  : AppColors.primary.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(5),
              border: Border.all(
                color: AppColors.black,
                width: isActive ? 1.5 : 0,
              ),
            ),
          ),
        );
      }),
    );
  }
}
