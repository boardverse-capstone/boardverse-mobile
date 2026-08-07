import 'package:flutter/material.dart';

import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../domain/entities/cafe_detail_entity.dart';

/// Pricing card hiển thị giá và tiền cọc của quán.
class PricingCard extends StatelessWidget {
  final CafeDetailEntity cafe;

  const PricingCard({super.key, required this.cafe});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: AppRadius.radiusMdAll,
        border: Border.all(color: theme.colorScheme.primaryContainer),
      ),
      child: Column(
        children: [
          // Price row
          Row(
            children: [
              Icon(
                Icons.sell_outlined,
                size: 24,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Giá thuê',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                    Text(
                      cafe.priceDisplay,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondaryContainer,
                  borderRadius: AppRadius.radiusSmAll,
                ),
                child: Text(
                  _billingModelLabel(cafe.billingModel),
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSecondaryContainer,
                  ),
                ),
              ),
            ],
          ),
          if (cafe.depositPercentage != null) ...[
            const SizedBox(height: AppSpacing.sm),
            const Divider(),
            const SizedBox(height: AppSpacing.sm),
            // Deposit row
            Row(
              children: [
                Icon(
                  Icons.payments_outlined,
                  size: 20,
                  color: theme.colorScheme.secondary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text('Tiền cọc', style: theme.textTheme.bodyMedium),
                ),
                Text(
                  cafe.depositDisplay,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
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