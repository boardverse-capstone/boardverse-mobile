import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';
import '../cubit/booking_summary_state.dart';
import 'booking_ui_helpers.dart';
import 'section_header.dart';

/// Card hiển thị breakdown giá đặt cọc — dùng ở `BookingSummaryPage`.
class DepositBreakdownCard extends StatelessWidget {
  final Breakdown breakdown;

  const DepositBreakdownCard({super.key, required this.breakdown});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pricingLabel = switch (breakdown.pricingModelLabel) {
      'flatEntry' => 'Phí cố định (vé vào cổng)',
      _ => 'Tính theo khối thời gian',
    };

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: AppRadius.cardRadius,
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
        boxShadow: AppElevation.shadowXxs,
      ),
      child: ClipRRect(
        borderRadius: AppRadius.cardRadius,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.warning.withValues(alpha: 0.12),
                    AppColors.warning.withValues(alpha: 0.02),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: SectionHeader(
                icon: Icons.receipt_long_rounded,
                title: 'Chi tiết cọc',
                subtitle: pricingLabel,
                accent: AppColors.warning,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                children: [
                  _row(
                    theme,
                    icon: Icons.access_time_rounded,
                    label: 'Giá giờ đầu',
                    value: BookingUiHelpers.formatVnd(breakdown.firstHourPrice),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.06),
                      borderRadius: AppRadius.radiusXsAll,
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.20),
                      ),
                    ),
                    child: _row(
                      theme,
                      icon: Icons.recommend_rounded,
                      label: 'Cọc khuyến nghị',
                      value: BookingUiHelpers.formatVnd(
                          breakdown.recommendedDeposit),
                      highlight: true,
                    ),
                  ),
                  _row(
                    theme,
                    icon: Icons.shield_outlined,
                    label: 'Cọc tối đa (BR-03)',
                    value: BookingUiHelpers.formatVnd(breakdown.maxDeposit),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(
    ThemeData theme, {
    required IconData icon,
    required String label,
    required String value,
    bool highlight = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.xs),
            decoration: BoxDecoration(
              color: (highlight
                      ? AppColors.primary
                      : theme.colorScheme.onSurfaceVariant)
                  .withValues(alpha: 0.12),
              borderRadius: AppRadius.radiusXxsAll,
            ),
            child: Icon(
              icon,
              size: AppIcons.md,
              color: highlight
                  ? AppColors.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight:
                    highlight ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: highlight
                  ? AppColors.primary
                  : theme.colorScheme.onSurface,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
