import 'package:flutter/material.dart';

import 'package:boardverse_mobile/core/theme/app_spacing.dart';
import 'package:boardverse_mobile/core/theme/app_colors.dart';
import 'package:boardverse_mobile/core/theme/neo_brutalism_theme.dart';

/// Neo-brutalism Stat Card - BIGGER
///
/// Features:
/// - Card to hơn, hiển thị nhiều info
/// - Brand colors với background tint
/// - Visual hierarchy rõ ràng
class ProfileStatCardNeo extends StatelessWidget {
  const ProfileStatCardNeo({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.accentColor,
    this.subtitle,
    this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color? accentColor;
  
  /// Optional subtitle (e.g., rank name, trend)
  final String? subtitle;
  
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final color = accentColor ?? AppColors.primary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: NeoBrutalismTheme.autoBox(
          context,
          backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surface,
          shadowColor: color.withValues(alpha: 0.15),
          borderRadius: 16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header: Icon + Label
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 18,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            
            // Value - BIG
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
                color: color,
                letterSpacing: -1,
                height: 1.1,
              ),
            ),
            
            // Subtitle (optional)
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(
                subtitle!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
