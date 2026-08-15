import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/neo_brutalism_theme.dart';

/// Neo-brutalism Summary row — icon badge + label + value.
///
/// Icon badge: nền `AppColors.primary`, icon trắng, viền border đậm +
/// hard shadow (2, 2). Label & value: text đậm, value màu primary.
class LobbyConfigSummaryRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const LobbyConfigSummaryRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          // Icon badge — neo style: nền primary, icon trắng, viền + shadow
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.border,
                width: NeoBrutalismTheme.borderWidth,
              ),
              boxShadow: NeoBrutalismTheme.lightShadow(
                shadowColor: AppColors.primary.withValues(alpha: 0.35),
              ),
            ),
            child: Icon(
              icon,
              size: 16,
              color: AppColors.white,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}