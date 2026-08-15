import 'package:flutter/material.dart';

import 'package:boardverse/core/theme/app_colors.dart';
import 'package:boardverse/core/theme/neo_brutalism_theme.dart';

/// Neo-brutalism Outlined card widget with hard border offset shadow.
class OutlinedCard extends StatelessWidget {
  const OutlinedCard({
    super.key,
    required this.child,
    this.borderColor,
    this.borderWidth,
    this.radius = 14,
    this.onTap,
    this.clipBehavior = Clip.antiAlias,
    this.backgroundColor,
    this.shadowColor,
  });

  final Widget child;
  final Color? borderColor;
  final double? borderWidth;
  final double radius;
  final VoidCallback? onTap;
  final Clip clipBehavior;
  final Color? backgroundColor;
  final Color? shadowColor;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveBorderColor = borderColor ??
        (isDark ? AppColors.borderDark : AppColors.border);
    final effectiveBorderWidth = borderWidth ?? NeoBrutalismTheme.borderWidth;
    final effectiveBg = backgroundColor ??
        (isDark ? AppColors.surfaceDark : AppColors.surface);

    return Material(
      color: effectiveBg,
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: effectiveBorderColor,
          width: effectiveBorderWidth,
        ),
        borderRadius: BorderRadius.circular(radius),
      ),
      clipBehavior: clipBehavior,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          boxShadow: NeoBrutalismTheme.lightShadow(
            shadowColor: shadowColor ?? AppColors.black.withValues(alpha: 0.06),
          ),
        ),
        child: onTap == null
            ? child
            : Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(radius),
                  child: child,
                ),
              ),
      ),
    );
  }
}