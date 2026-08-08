import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/neo_brutalism_theme.dart';

/// Neo-brutalism SePay badge hiển thị quán có thanh toán SePay.
class SePayBadge extends StatelessWidget {
  const SePayBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.success,
          width: NeoBrutalismTheme.borderWidthBold,
        ),
        boxShadow: NeoBrutalismTheme.lightShadow(
          shadowColor: AppColors.success.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.success,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.verified,
              size: 14,
              color: AppColors.white,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            'Hỗ trợ thanh toán SePay',
            style: theme.textTheme.labelMedium?.copyWith(
              color: AppColors.success,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
