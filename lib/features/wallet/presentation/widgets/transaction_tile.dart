import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/entities.dart';

/// Widget hiển thị một giao dịch trong lịch sử
class TransactionTile extends StatelessWidget {
  final TransactionEntity transaction;
  final VoidCallback? onTap;

  const TransactionTile({
    super.key,
    required this.transaction,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isPositive = transaction.amount > 0;
    final amountColor = isPositive ? Colors.green : Colors.red;
    final amountPrefix = isPositive ? '+' : '';

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            _buildIcon(transaction.type),
            SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getTransactionTitle(transaction.type),
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: AppSpacing.xxs),
                  Text(
                    _formatDate(transaction.createdAt),
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$amountPrefix${transaction.amount} BVC',
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: amountColor,
                  ),
                ),
                if (transaction.relatedPaymentRef != null) ...[
                  SizedBox(height: AppSpacing.xxs),
                  Text(
                    _formatVnd(transaction.amountVnd),
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon(TransactionType type) {
    IconData icon;
    Color color;

    switch (type) {
      case TransactionType.topUp:
        icon = Icons.add_circle_outline;
        color = Colors.green;
      case TransactionType.depositHold:
        icon = Icons.lock_outline;
        color = Colors.orange;
      case TransactionType.depositRelease:
        icon = Icons.lock_open_outlined;
        color = Colors.blue;
      case TransactionType.depositCapture:
        icon = Icons.remove_circle_outline;
        color = Colors.red;
      case TransactionType.depositForfeit:
        icon = Icons.warning_outlined;
        color = Colors.red.shade700;
      case TransactionType.adjustment:
        icon = Icons.tune;
        color = Colors.teal;
      case TransactionType.adminCredit:
        icon = Icons.admin_panel_settings_outlined;
        color = Colors.purple;
      case TransactionType.adminDebit:
        icon = Icons.admin_panel_settings_outlined;
        color = Colors.orange;
    }

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color, size: 22),
    );
  }

  String _getTransactionTitle(TransactionType type) {
    switch (type) {
      case TransactionType.topUp:
        return 'Nạp BVC';
      case TransactionType.depositHold:
        return 'Giữ cọc';
      case TransactionType.depositRelease:
        return 'Hoàn cọc';
      case TransactionType.depositCapture:
        return 'Thanh toán cọc';
      case TransactionType.depositForfeit:
        return 'Phạt cọc';
      case TransactionType.adjustment:
        return 'Điều chỉnh';
      case TransactionType.adminCredit:
        return 'Tặng thưởng';
      case TransactionType.adminDebit:
        return 'Trừ tài khoản';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'Hôm nay, ${_formatTime(date)}';
    } else if (diff.inDays == 1) {
      return 'Hôm qua, ${_formatTime(date)}';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} ngày trước';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _formatVnd(int amount) {
    final str = amount.toString();
    final result = StringBuffer();
    for (var i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) {
        result.write(',');
      }
      result.write(str[i]);
    }
    return '$result đ';
  }
}
