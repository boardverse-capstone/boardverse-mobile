import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/neo_brutalism_theme.dart';
import '../../../domain/entities/cafe_detail_entity.dart';

/// Card hiển thị thông tin đặt cọc của quán:
/// - Tỷ lệ cọc theo hoá đơn (depositPercentage, 0.0–1.0)
/// - Tỷ lệ cọc theo đầu người (depositRatePerPerson, %)
/// - Cọc tối thiểu (minDeposit, optional — VNĐ)
///
/// Chỉ render khi quán thật sự có cọc > 0.
class DepositCard extends StatelessWidget {
  final CafeDetailEntity cafe;

  const DepositCard({super.key, required this.cafe});

  bool get _hasDeposit =>
      cafe.depositPercentage > 0 ||
      cafe.depositRatePerPerson > 0 ||
      cafe.minDeposit != null;

  @override
  Widget build(BuildContext context) {
    if (!_hasDeposit) return const SizedBox.shrink();

    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.warning.withValues(alpha: 0.5),
          width: NeoBrutalismTheme.borderWidth,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.warning,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_rounded,
                  size: 22,
                  color: AppColors.white,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'ĐẶT CỌC',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (cafe.depositPercentage > 0)
            _DepositRow(
              icon: Icons.percent_rounded,
              label: 'Tỷ lệ cọc theo hoá đơn',
              value: cafe.depositPercentDisplay,
            ),
          if (cafe.depositRatePerPerson > 0) ...[
            if (cafe.depositPercentage > 0)
              const SizedBox(height: AppSpacing.xs),
            _DepositRow(
              icon: Icons.person_rounded,
              label: 'Tỷ lệ cọc theo người',
              value: '${cafe.depositRatePerPerson}%',
            ),
          ],
          if (cafe.minDeposit != null && cafe.minDeposit! > 0) ...[
            if (cafe.depositPercentage > 0 || cafe.depositRatePerPerson > 0)
              const SizedBox(height: AppSpacing.xs),
            _DepositRow(
              icon: Icons.price_change_rounded,
              label: 'Cọc tối thiểu',
              value: '${_formatVnd(cafe.minDeposit!)} đ',
            ),
          ],
        ],
      ),
    );
  }

  static String _formatVnd(int v) {
    if (v >= 1000000) {
      return '${(v / 1000000).toStringAsFixed(1)}tr';
    }
    if (v >= 1000) {
      return '${(v / 1000).toStringAsFixed(0)}k';
    }
    return '$v';
  }
}

class _DepositRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DepositRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.warningDark),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xs,
            vertical: 2,
          ),
          decoration: BoxDecoration(
            color: AppColors.warning.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            value,
            style: TextStyle(
              color: AppColors.warningDark,
              fontWeight: FontWeight.w900,
              fontSize: 13,
            ),
          ),
        ),
        if (isDark) const SizedBox.shrink(),
      ],
    );
  }
}