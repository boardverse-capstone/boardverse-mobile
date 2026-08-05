import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_icons.dart';

/// Reusable meta row widget showing karma points and mutual friends count.
class MetaRow extends StatelessWidget {
  const MetaRow({
    super.key,
    this.karmaPoints,
    this.mutualFriendsCount,
    this.compact = false,
  });

  final int? karmaPoints;
  final int? mutualFriendsCount;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = <Widget>[];

    if (karmaPoints != null && karmaPoints! > 0) {
      items.addAll([
        Icon(
          Icons.local_fire_department_outlined,
          size: compact ? AppIcons.xs : AppIcons.sm,
          color: AppColors.warning,
        ),
        SizedBox(width: compact ? 1 : AppSpacing.xxs),
        Text(
          '$karmaPoints',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
      ]);
    }

    if (mutualFriendsCount != null && mutualFriendsCount! > 0) {
      if (items.isNotEmpty) {
        items.addAll([
          SizedBox(width: compact ? AppSpacing.xxs : AppSpacing.xs),
          Text(
            '·',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
          SizedBox(width: compact ? AppSpacing.xxs : AppSpacing.xs),
        ]);
      }
      items.addAll([
        Icon(
          Icons.people_alt_outlined,
          size: compact ? AppIcons.xs : AppIcons.sm,
          color: theme.colorScheme.outline,
        ),
        SizedBox(width: compact ? 1 : AppSpacing.xxs),
        Text(
          '$mutualFriendsCount${compact ? '' : ' bạn chung'}',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.outline,
          ),
        ),
      ]);
    }

    if (items.isEmpty) return const SizedBox.shrink();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: items,
    );
  }
}
