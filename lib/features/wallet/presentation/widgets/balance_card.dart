import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/neo_brutalism_theme.dart';
import '../../domain/entities/entities.dart';

/// Neo-brutalism Widget hiển thị số dư ví BVC.
class BalanceCard extends StatelessWidget {
  final WalletEntity wallet;
  final VoidCallback? onTopUpPressed;

  const BalanceCard({
    super.key,
    required this.wallet,
    this.onTopUpPressed,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.borderDark : AppColors.border;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryLight],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: NeoBrutalismTheme.borderWidthBold),
        boxShadow: [
          // Hard neo-brutalism shadow offset
          const BoxShadow(
            color: AppColors.black,
            blurRadius: 0,
            offset: Offset(4, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'SỐ DƯ BVC',
                style: TextStyle(
                  color: AppColors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  letterSpacing: 1.5,
                ),
              ),
              _buildRiskBadge(),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${wallet.availableBalance}',
                style: textTheme.headlineLarge?.copyWith(
                  color: AppColors.white,
                  fontSize: 40,
                  fontWeight: FontWeight.w900,
                  shadows: const [
                    Shadow(
                      color: AppColors.black,
                      offset: Offset(0, 2),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: AppSpacing.xs, left: 4),
                child: Text(
                  'BVC',
                  style: TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ],
          ),
          if (onTopUpPressed != null) ...[
            const SizedBox(height: AppSpacing.lg),
            Container(
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: borderColor,
                  width: NeoBrutalismTheme.borderWidth,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.black,
                    blurRadius: 0,
                    offset: Offset(2, 2),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: onTopUpPressed,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add, color: AppColors.primary),
                        SizedBox(width: AppSpacing.xs),
                        Text(
                          'NẠP BVC',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Text(
            '≈ ${_formatVnd(wallet.availableBalanceVnd)} VND',
            style: TextStyle(
              color: AppColors.white.withValues(alpha: 0.85),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiskBadge() {
    Color badgeBg;
    Color badgeTextColor;

    switch (wallet.riskLevel) {
      case RiskLevel.low:
        badgeBg = AppColors.success;
        badgeTextColor = AppColors.white;
      case RiskLevel.medium:
        badgeBg = AppColors.warning;
        badgeTextColor = AppColors.black;
      case RiskLevel.high:
        badgeBg = AppColors.warning;
        badgeTextColor = AppColors.black;
      case RiskLevel.critical:
        badgeBg = AppColors.error;
        badgeTextColor = AppColors.white;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs + 2,
      ),
      decoration: BoxDecoration(
        color: badgeBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.black,
          width: 2,
        ),
        boxShadow: const [
          BoxShadow(
            color: AppColors.black,
            blurRadius: 0,
            offset: Offset(2, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.shield_outlined,
            size: 12,
            color: badgeTextColor,
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            _riskLabel(wallet.riskLevel),
            style: TextStyle(
              color: badgeTextColor,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  String _riskLabel(RiskLevel level) {
    switch (level) {
      case RiskLevel.low:
        return 'AN TOÀN';
      case RiskLevel.medium:
        return 'TRUNG BÌNH';
      case RiskLevel.high:
        return 'CAO';
      case RiskLevel.critical:
        return 'NGUY HIỂM';
    }
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