import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';

/// Neo-brutalism Section title trong FilterBottomSheet.
class FilterSectionTitle extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? trailing;

  const FilterSectionTitle({
    super.key,
    required this.icon,
    required this.label,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: theme.brightness == Brightness.dark
                  ? AppColors.borderDark
                  : AppColors.border,
              width: 2,
            ),
          ),
          child: Icon(
            icon,
            size: AppSpacing.md,
            color: AppColors.white,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          label.toUpperCase(),
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xxs,
            ),
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: theme.brightness == Brightness.dark
                    ? AppColors.borderDark
                    : AppColors.border,
                width: 2,
              ),
            ),
            child: Text(
              trailing!,
              style: const TextStyle(
                color: AppColors.black,
                fontWeight: FontWeight.w900,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
