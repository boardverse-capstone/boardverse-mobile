import 'package:flutter/material.dart';

import 'package:boardverse/core/theme/app_colors.dart';
import 'package:boardverse/core/theme/app_spacing.dart';
import 'package:boardverse/core/theme/neo_brutalism_theme.dart';
import 'package:boardverse/core/widgets/safe_network_image.dart';
import 'package:boardverse/features/leaderboard/domain/entities/leaderboard_entry_entity.dart';
import 'package:boardverse/features/leaderboard/domain/entities/leaderboard_kind.dart';
import 'package:boardverse/features/leaderboard/presentation/widgets/gamer_tier_color.dart';
import 'package:boardverse/features/leaderboard/presentation/widgets/leaderboard_metric.dart';
import 'package:boardverse/features/leaderboard/presentation/widgets/tier_badge.dart';

/// Card strip cho "Thứ hạng của bạn" — hiển thị khi response có
/// `userRank` (yêu cầu JWT).
///
/// Layout neo-brutalism:
///   [Rank pill primary] [Avatar + Name + tier] [Metric số lớn]
class UserRankCard extends StatelessWidget {
  final LeaderboardEntryEntity userRank;
  final LeaderboardKind kind;

  const UserRankCard({
    super.key,
    required this.userRank,
    required this.kind,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final metric = LeaderboardMetric.resolve(userRank, kind);
    final tierColor = userRank.gamerTier.accentColor;

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: NeoBrutalismTheme.autoBox(
        context,
        backgroundColor: AppColors.primary.withValues(alpha: 0.10),
        borderColor: AppColors.primary,
        shadowColor: AppColors.primary.withValues(alpha: 0.25),
        bold: true,
        borderRadius: 16,
      ),
      child: Row(
        children: [
          // Rank pill
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: NeoBrutalismTheme.brutalBox(
              backgroundColor: AppColors.primary,
              borderColor: AppColors.border,
              shadowColor: Colors.black.withValues(alpha: 0.4),
              borderRadius: 10,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '#${userRank.rank}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: AppColors.white,
                    height: 1,
                  ),
                ),
                Text(
                  'BẠN',
                  style: const TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    color: AppColors.white,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          // Avatar + name + tier
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: tierColor.withValues(alpha: 0.18),
              shape: BoxShape.circle,
              border: Border.all(
                color: tierColor,
                width: NeoBrutalismTheme.borderWidthBold,
              ),
            ),
            child: ClipOval(
              child: userRank.avatarUrl != null && userRank.avatarUrl!.isNotEmpty
                  ? SafeNetworkImage(
                      url: userRank.avatarUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _Initial(text: userRank.resolvedName, color: tierColor),
                    )
                  : _Initial(text: userRank.resolvedName, color: tierColor),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  userRank.resolvedName,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xxs),
                Row(
                  children: [
                    TierBadge(tier: userRank.gamerTier, compact: true),
                    const SizedBox(width: AppSpacing.xs),
                    if (userRank.level != null)
                      Text(
                        'Lv.${userRank.level}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  'Thứ hạng của bạn',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          // Metric value lớn
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                metric.value,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: metric.accentColor,
                  letterSpacing: -0.5,
                  height: 1,
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(metric.icon, size: 12, color: metric.accentColor),
                  const SizedBox(width: 4),
                  Text(
                    metric.label,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurfaceVariant,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Initial extends StatelessWidget {
  final String text;
  final Color color;
  const _Initial({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    final initial = text.isNotEmpty ? text.characters.first.toUpperCase() : '?';
    return Container(
      color: color.withValues(alpha: 0.2),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w900,
          color: color,
        ),
      ),
    );
  }
}
