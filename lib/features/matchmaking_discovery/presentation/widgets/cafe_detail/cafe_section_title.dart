import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';

/// Neo-brutalism Section title dùng trong CafeDetailPage.
class CafeSectionTitle extends StatelessWidget {
  final String title;
  final IconData? icon;

  const CafeSectionTitle({super.key, required this.title, this.icon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        if (icon != null) ...[
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              icon,
              size: 14,
              color: AppColors.white,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
        Text(
          title.toUpperCase(),
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}
