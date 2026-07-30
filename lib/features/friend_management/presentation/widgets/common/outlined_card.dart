import 'package:flutter/material.dart';

import '../../../../../core/theme/app_radius.dart';

/// Outlined card widget with configurable border and tap behavior.
class OutlinedCard extends StatelessWidget {
  const OutlinedCard({
    super.key,
    required this.child,
    this.borderColor,
    this.borderWidth = 1,
    this.radius = AppRadius.radiusMd,
    this.onTap,
    this.clipBehavior = Clip.antiAlias,
    this.backgroundColor,
  });

  final Widget child;
  final Color? borderColor;
  final double borderWidth;
  final double radius;
  final VoidCallback? onTap;
  final Clip clipBehavior;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveBorderColor =
        borderColor ?? theme.colorScheme.outlineVariant.withValues(alpha: 0.6);
    final effectiveBg = backgroundColor ?? theme.colorScheme.surface;

    return Material(
      color: effectiveBg,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: effectiveBorderColor, width: borderWidth),
        borderRadius: BorderRadius.circular(radius),
      ),
      clipBehavior: clipBehavior,
      child: onTap == null
          ? child
          : InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(radius),
              child: child,
            ),
    );
  }
}
