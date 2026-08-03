import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/entities.dart';

/// Widget hiển thị số dư ví BVC (BR §2.4)
///
/// Hiển thị:
/// - availableBalance: Số BVC có thể dùng
/// - heldBalance: Số BVC đang bị giữ
/// - Tổng số dư
class BalanceCard extends StatelessWidget {
  final WalletEntity wallet;
  final bool showHeldBalance;
  final VoidCallback? onTopUpPressed;

  const BalanceCard({
    super.key,
    required this.wallet,
    this.showHeldBalance = true,
    this.onTopUpPressed,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.primary.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.radiusXl),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Số dư BVC',
                style: textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
              _buildRiskBadge(textTheme),
            ],
          ),
          SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${wallet.availableBalance}',
                style: textTheme.headlineLarge?.copyWith(
                  color: Colors.white,
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 8, left: 4),
                child: Text(
                  'BVC',
                  style: textTheme.titleMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ),
            ],
          ),
          if (showHeldBalance && wallet.heldBalance > 0) ...[
            SizedBox(height: AppSpacing.sm),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(AppRadius.radiusSm),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.lock_outline,
                    size: 14,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                  SizedBox(width: AppSpacing.xs),
                  Text(
                    '${wallet.heldBalance} BVC đang giữ',
                    style: textTheme.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (onTopUpPressed != null) ...[
            SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onTopUpPressed,
                icon: Icon(Icons.add),
                label: const Text('Nạp BVC'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primary,
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.radiusMd),
                  ),
                ),
              ),
            ),
          ],
          SizedBox(height: AppSpacing.sm),
          Text(
            '≈ ${_formatVnd(wallet.availableBalanceVnd)} VND',
            style: textTheme.bodySmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiskBadge(TextTheme textTheme) {
    Color badgeColor;
    String label;

    switch (wallet.riskLevel) {
      case RiskLevel.low:
        badgeColor = Colors.green;
        label = 'Thấp';
      case RiskLevel.medium:
        badgeColor = Colors.orange;
        label = 'Trung bình';
      case RiskLevel.high:
        badgeColor = Colors.red.shade400;
        label = 'Cao';
      case RiskLevel.critical:
        badgeColor = Colors.red;
        label = 'Nguy hiểm';
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(AppRadius.radiusSm),
        border: Border.all(color: badgeColor.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.shield_outlined,
            size: 12,
            color: badgeColor,
          ),
          SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: textTheme.labelSmall?.copyWith(
              color: badgeColor,
            ),
          ),
        ],
      ),
    );
  }

  String _formatVnd(int amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}K';
    }
    return amount.toString();
  }
}
