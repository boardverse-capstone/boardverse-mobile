import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/neo_brutalism_theme.dart';
import '../theme/app_spacing.dart';

/// Neo-brutalism Toast Card
/// 
/// Features:
/// - Bold borders
/// - Hard offset shadows
/// - Rounded corners
class AppToastCard extends StatelessWidget {
  final Widget title;
  final Widget? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final Color? color;
  final Color? shadowColor;
  final VoidCallback? onTap;

  const AppToastCard({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.color,
    this.shadowColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final effectiveColor = color ?? (isDark ? AppColors.surfaceDark : AppColors.surface);
    final effectiveShadowColor = shadowColor ?? Colors.black.withValues(alpha: 0.15);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: effectiveColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.border,
          width: NeoBrutalismTheme.borderWidth,
        ),
        boxShadow: [
          BoxShadow(
            color: effectiveShadowColor,
            blurRadius: 0,
            offset: const Offset(3, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          contentPadding: const EdgeInsets.all(AppSpacing.sm),
          leading: leading != null
              ? Padding(
                  padding: const EdgeInsets.all(AppSpacing.xs),
                  child: leading,
                )
              : null,
          trailing: trailing,
          subtitle: subtitle,
          title: title,
          onTap: onTap,
        ),
      ),
    );
  }
}

/// Success Toast variant
class SuccessToastCard extends StatelessWidget {
  const SuccessToastCard({
    super.key,
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return AppToastCard(
      leading: Container(
        padding: const EdgeInsets.all(AppSpacing.xs),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.check_circle_outlined,
          color: AppColors.success,
          size: 24,
        ),
      ),
      title: Text(
        message,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.success,
        ),
      ),
    );
  }
}

/// Error Toast variant
class ErrorToastCard extends StatelessWidget {
  const ErrorToastCard({
    super.key,
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return AppToastCard(
      leading: Container(
        padding: const EdgeInsets.all(AppSpacing.xs),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.error_outline,
          color: AppColors.error,
          size: 24,
        ),
      ),
      title: Text(
        message,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.error,
        ),
      ),
    );
  }
}
