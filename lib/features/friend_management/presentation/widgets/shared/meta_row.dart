import 'package:flutter/material.dart';

import 'package:boardverse_mobile/core/theme/app_colors.dart';
import 'package:boardverse_mobile/core/theme/app_spacing.dart';
import 'package:boardverse_mobile/core/theme/app_icons.dart';

/// Neo-brutalism Reusable meta row widget showing karma points và mutual friends.
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final items = <Widget>[];

    if (karmaPoints != null && karmaPoints! > 0) {
      items.addAll([
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: AppColors.warning,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: AppColors.black, width: 1),
          ),
          child: Icon(
            AppIcons.karma,
            size: compact ? 10 : AppIcons.xs,
            color: AppColors.black,
          ),
        ),
        SizedBox(width: compact ? 4 : 6),
        Text(
          '$karmaPoints',
          style: TextStyle(
            color: isDark
                ? AppColors.textPrimaryDark
                : AppColors.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
      ]);
    }

    if (mutualFriendsCount != null && mutualFriendsCount! > 0) {
      if (items.isNotEmpty) {
        items.addAll([
          SizedBox(width: compact ? AppSpacing.xs : AppSpacing.sm),
          const Text(
            '·',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(width: compact ? AppSpacing.xs : AppSpacing.sm),
        ]);
      }
      items.addAll([
        Icon(
          Icons.people_alt_outlined,
          size: compact ? AppIcons.xs : AppIcons.sm,
          color: isDark
              ? AppColors.textSecondaryDark
              : AppColors.textSecondary,
        ),
        SizedBox(width: compact ? 4 : 6),
        Text(
          '$mutualFriendsCount${compact ? '' : ' bạn chung'}',
          style: TextStyle(
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
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