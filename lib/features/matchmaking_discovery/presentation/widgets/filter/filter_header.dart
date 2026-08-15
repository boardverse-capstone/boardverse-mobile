import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';

/// Neo-brutalism Header cho FilterBottomSheet — drag handle + title + Reset.
class FilterHeader extends StatelessWidget {
  final VoidCallback onReset;

  const FilterHeader({super.key, required this.onReset});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        // Drag handle
        Container(
          margin: const EdgeInsets.only(top: AppSpacing.xs + 2),
          width: 48,
          height: 5,
          decoration: BoxDecoration(
            color: isDark ? AppColors.borderDark : AppColors.border,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.xs,
            AppSpacing.xs,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.xs),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDark ? AppColors.borderDark : AppColors.border,
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.tune,
                  size: AppSpacing.lg,
                  color: AppColors.white,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'BỘ LỌC',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
              ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onReset,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.error,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'ĐẶT LẠI',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: AppColors.error,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Divider(
          height: 1,
          thickness: 2,
          color: isDark ? AppColors.borderDark : AppColors.border,
        ),
      ],
    );
  }
}
