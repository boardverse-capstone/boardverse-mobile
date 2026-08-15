import 'package:flutter/material.dart';

import 'package:boardverse/core/theme/app_colors.dart';
import 'package:boardverse/core/theme/app_icons.dart';
import 'package:boardverse/core/theme/app_spacing.dart';
import 'package:boardverse/core/theme/neo_brutalism_theme.dart';

/// Neo-brutalism Bọc ngoài thống nhất cho mọi "card" trong profile.
class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.child,
    this.padding = AppSpacing.paddingAllMd,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: isDark ? AppColors.surfaceDark : AppColors.surface,
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: isDark ? AppColors.borderDark : AppColors.border,
          width: NeoBrutalismTheme.borderWidth,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          boxShadow: NeoBrutalismTheme.lightShadow(
            shadowColor: AppColors.black.withValues(alpha: 0.06),
          ),
        ),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

/// Tiêu đề section — neo-brutalism icon badge + uppercase title.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.icon,
    required this.title,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.border,
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
          child: Icon(
            icon,
            color: AppColors.white,
            size: AppIcons.md,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            title.toUpperCase(),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimary,
              letterSpacing: 0.5,
            ),
          ),
        ),
        ?trailing,
      ],
    );
  }
}
