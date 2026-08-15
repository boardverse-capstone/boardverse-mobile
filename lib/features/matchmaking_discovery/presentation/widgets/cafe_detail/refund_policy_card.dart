import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/neo_brutalism_theme.dart';
import '../../../domain/entities/cafe_detail_entity.dart';

/// Card hiển thị chính sách hoàn tiền của quán:
/// - refundPolicy (Full / Partial / None)
/// - refundTiers[]: danh sách "Hủy trước X giờ → hoàn Y%"
class RefundPolicyCard extends StatelessWidget {
  final CafeDetailEntity cafe;

  const RefundPolicyCard({super.key, required this.cafe});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cfg = _policyConfig(cafe.refundPolicy);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: cfg.bg.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: cfg.bg.withValues(alpha: 0.4),
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
                  color: cfg.bg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(cfg.icon, size: 22, color: AppColors.white),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CHÍNH SÁCH HOÀN TIỀN',
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
                      cfg.label,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: cfg.bg,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (cafe.refundTiers.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            const Divider(height: 1),
            const SizedBox(height: AppSpacing.sm),
            ...cafe.refundTiers.map(
              (tier) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(
                      Icons.arrow_right_alt_rounded,
                      size: 16,
                      color: cfg.bg,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        tier.displayLabel,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  _PolicyConfig _policyConfig(RefundPolicy policy) {
    switch (policy) {
      case RefundPolicy.full:
        return const _PolicyConfig(
          bg: AppColors.success,
          icon: Icons.replay_circle_filled_rounded,
          label: 'Hoàn 100%',
        );
      case RefundPolicy.partial:
        return const _PolicyConfig(
          bg: AppColors.warning,
          icon: Icons.policy_rounded,
          label: 'Hoàn một phần',
        );
      case RefundPolicy.none:
        return const _PolicyConfig(
          bg: AppColors.error,
          icon: Icons.do_not_disturb_alt_rounded,
          label: 'Không hoàn',
        );
    }
  }
}

class _PolicyConfig {
  final Color bg;
  final IconData icon;
  final String label;
  const _PolicyConfig({
    required this.bg,
    required this.icon,
    required this.label,
  });
}