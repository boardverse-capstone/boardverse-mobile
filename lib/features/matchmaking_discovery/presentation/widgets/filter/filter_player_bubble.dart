import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/neo_brutalism_theme.dart';

/// Neo-brutalism Player bubble — số người Min/Max.
class FilterPlayerBubble extends StatelessWidget {
  final String label;
  final int value;

  const FilterPlayerBubble({
    super.key,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.xs + 2,
        horizontal: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.border,
          width: NeoBrutalismTheme.borderWidth,
        ),
        boxShadow: NeoBrutalismTheme.lightShadow(
          shadowColor: AppColors.primary.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: AppColors.white,
              fontWeight: FontWeight.w900,
              fontSize: 11,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$value',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  color: AppColors.white,
                  fontSize: 28,
                  height: 1,
                ),
              ),
              const SizedBox(width: AppSpacing.xxs),
              const Padding(
                padding: EdgeInsets.only(bottom: AppSpacing.xxs),
                child: Text(
                  'người',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
