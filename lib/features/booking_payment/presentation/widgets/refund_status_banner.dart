import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/theme.dart';
import '../../domain/entities/deposit_status_entity.dart';

/// Banner hiển thị trên `BookingDetailPage` khi booking đã ở trạng thái
/// terminal (cancelled / noShow) và backend trả về trạng thái cọc tương ứng
/// (refunded / forfeited).
///
/// Mục tiêu UX (BR-18): Player thấy rõ "đã được hoàn X VND" hoặc
/// "cọc bị tịch thu theo policy" thay vì phải tự vào lịch sử SePay.
class RefundStatusBanner extends StatelessWidget {
  final DepositStatusEntity depositStatus;

  const RefundStatusBanner({super.key, required this.depositStatus});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isRefunded = depositStatus.status == DepositStatus.refunded;
    final color = isRefunded ? AppColors.success : AppColors.error;
    final icon = isRefunded
        ? Icons.replay_circle_filled_rounded
        : Icons.do_disturb_alt_rounded;
    final title = isRefunded
        ? 'Đã hoàn cọc'
        : 'Cọc đã bị tịch thu';

    final refundedAmount = depositStatus.refundedAmount ?? 0;
    final formatter = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '₫',
      decimalDigits: 0,
    );

    final body = isRefunded
        ? 'Bạn đã được hoàn ${formatter.format(refundedAmount)}'
              '${depositStatus.refundPolicy != null ? " theo chính sách ${_policyLabel(depositStatus.refundPolicy!)}" : ""}.'
        : 'Theo chính sách ${_policyLabel(depositStatus.refundPolicy ?? RefundPolicy.none)}, cọc đã bị tịch thu.';

    final timestamp = depositStatus.refundedAt ?? depositStatus.forfeitedAt;
    final tsLabel = timestamp != null
        ? ' (${MaterialLocalizations.of(context).formatShortDate(timestamp)})'
        : '';

    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: AppRadius.radiusMdAll,
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$title$tsLabel',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  body,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                if (depositStatus.transferContent != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Mã tham chiếu: ${depositStatus.transferContent}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _policyLabel(RefundPolicy policy) {
    switch (policy) {
      case RefundPolicy.full:
        return 'hoàn 100%';
      case RefundPolicy.partial:
        return 'hoàn một phần';
      case RefundPolicy.none:
        return 'không hoàn';
    }
  }
}