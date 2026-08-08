import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';

/// Neo-brutalism Small icon + label chip.
class CafeChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final Color? textColor;

  const CafeChip({
    super.key,
    required this.icon,
    required this.label,
    this.color,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final bg = color ?? AppColors.surfaceVariant;
    final fg = textColor ?? AppColors.textPrimary;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: fg.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: AppSpacing.sm, color: fg),
          const SizedBox(width: AppSpacing.xxs),
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontWeight: FontWeight.w800,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
