import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';

/// Badge "Vắng" hiển thị cho booking đã đặt cọc nhưng không đến check-in.
class NoShowBadge extends StatelessWidget {
  const NoShowBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.10),
        borderRadius: AppRadius.tagRadius,
        border: Border.all(
          color: AppColors.error.withValues(alpha: 0.30),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.person_off_rounded,
            size: AppIcons.sm,
            color: AppColors.error,
          ),
          const SizedBox(width: AppSpacing.xxs),
          Text(
            'Vắng',
            style: theme.textTheme.labelMedium?.copyWith(
              color: AppColors.error,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
