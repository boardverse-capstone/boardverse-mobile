import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_icons.dart';
import '../../domain/entities/entities.dart';

/// Neo-brutalism Widget hiển thị một giao dịch trong lịch sử.
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isCredit = transaction.isCredit;
    final amountColor = isCredit ? AppColors.success : AppColors.error;
    // Prefix đúng kiểu Việt: cộng = '+' ASCII, trừ = U+2212 MINUS SIGN
    // cho đẹp alignment (không phải dấu trừ ASCII ngắn hơn).
    final amountPrefix = isCredit ? '+' : '−';

    return Material(
      color: isDark ? AppColors.surfaceDark : AppColors.surface,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isDark
                    ? AppColors.borderDark
                    : AppColors.border,
                width: 1.5,
              ),
            ),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              _buildIcon(transaction.type),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getTransactionTitle(transaction.type),
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      _formatDate(transaction.createdAt),
                      style: textTheme.bodySmall?.copyWith(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: amountColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: amountColor, width: 1.5),
                    ),
                    child: Text(
                      '$amountPrefix${transaction.amount.abs()} BVC',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: amountColor,
                      ),
                    ),
                  ),
                  if (transaction.relatedPaymentRef != null) ...[
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      _formatVnd(transaction.amountVndAbs),
                      style: textTheme.bodySmall?.copyWith(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
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
        color = AppColors.success;
      case TransactionType.depositHold:
        icon = Icons.lock_outline;
        color = AppColors.warning;
      case TransactionType.depositRelease:
        icon = Icons.lock_open_outlined;
        color = AppColors.info;
      case TransactionType.depositCapture:
        icon = Icons.remove_circle_outline;
        color = AppColors.error;
      case TransactionType.depositForfeit:
        icon = Icons.warning_outlined;
        color = AppColors.error;
      case TransactionType.adjustment:
        icon = Icons.tune;
        color = AppColors.secondary;
      case TransactionType.adminCredit:
        icon = Icons.admin_panel_settings_outlined;
        color = AppColors.primary;
      case TransactionType.adminDebit:
        icon = Icons.admin_panel_settings_outlined;
        color = AppColors.warning;
    }

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.black, width: 2),
        boxShadow: const [
          BoxShadow(
            color: AppColors.black,
            blurRadius: 0,
            offset: Offset(2, 2),
          ),
        ],
      ),
      child: Icon(icon, color: AppColors.white, size: AppIcons.md),
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