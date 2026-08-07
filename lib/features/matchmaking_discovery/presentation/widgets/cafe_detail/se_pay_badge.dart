import 'package:flutter/material.dart';

import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';

/// SePay badge hiển thị quán có thanh toán SePay.
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
        color: Colors.green.withValues(alpha: 0.1),
        borderRadius: AppRadius.radiusSmAll,
        border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.verified, size: 18, color: Colors.green),
          const SizedBox(width: AppSpacing.xs),
          Text(
            'Hỗ trợ thanh toán SePay',
            style: theme.textTheme.labelMedium?.copyWith(
              color: Colors.green.shade700,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}