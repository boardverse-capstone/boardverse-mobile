import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';
import '../../domain/entities/deposit_status_entity.dart';

/// Badge hoàn cọc / tịch thu cọc — render ở `BookingDetailPage` khi
/// `BookingEntity.depositRefundStatus` thuộc Refunded/Forfeited (gap #11).
class DepositRefundBadge extends StatelessWidget {
  final DepositStatus status;

  /// Số tiền đã hoàn (VND). Null nếu chưa refund.
  final double? refundAmount;

  const DepositRefundBadge({
    super.key,
    required this.status,
    this.refundAmount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = status == DepositStatus.refunded
        ? AppColors.success
        : AppColors.error;
    final icon = status == DepositStatus.refunded
        ? Icons.assignment_return_rounded
        : Icons.gavel_rounded;
    final headline = status == DepositStatus.refunded
        ? 'Đã hoàn cọc'
        : 'Đã tịch thu cọc';
    final subline = status == DepositStatus.refunded
        ? refundAmount != null
            ? 'Số tiền hoàn: ${_formatVnd(refundAmount!)}'
            : 'Số tiền hoàn sẽ hiển thị sau khi Manager xử lý.'
        : 'Theo chính sách BR-10 — cọc không được hoàn do vi phạm khung giờ.';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: AppRadius.cardRadius,
        border: Border.all(color: color.withValues(alpha: 0.40)),
      ),
      child: Row(
        children: [
          Icon(icon, size: AppIcons.lg, color: color),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  headline,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subline,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatVnd(double amount) {
    final s = amount.toStringAsFixed(0);
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return '$buf đ';
  }
}