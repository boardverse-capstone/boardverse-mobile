import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/neo_brutalism_theme.dart';
import '../../../domain/entities/cafe_detail_entity.dart';

/// Neo-brutalism Pricing card hiển thị giá và tiền cọc của quán.
class PricingCard extends StatelessWidget {
  final CafeDetailEntity cafe;

  const PricingCard({super.key, required this.cafe});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary,
          width: NeoBrutalismTheme.borderWidthBold,
        ),
        boxShadow: NeoBrutalismTheme.lightShadow(
          shadowColor: AppColors.primary.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.sell_outlined,
                  size: 22,
                  color: AppColors.white,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'GIÁ THUÊ',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondary,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      cafe.priceDisplay,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xxs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDark ? AppColors.borderDark : AppColors.border,
                    width: NeoBrutalismTheme.borderWidth,
                  ),
                ),
                child: Text(
                  _billingModelLabel(cafe.billingModel),
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: AppColors.black,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _billingModelLabel(BillingModel model) {
    switch (model) {
      case BillingModel.timeBased:
        return 'Theo giờ';
      case BillingModel.fixed:
        return 'Cố định';
      case BillingModel.tiered:
        return 'Lũy tiến';
    }
  }
}
