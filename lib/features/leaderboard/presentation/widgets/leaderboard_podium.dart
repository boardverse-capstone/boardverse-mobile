import 'package:flutter/material.dart';

import 'package:boardverse/core/theme/app_colors.dart';
import 'package:boardverse/core/theme/app_spacing.dart';
import 'package:boardverse/core/theme/neo_brutalism_theme.dart';
import 'package:boardverse/core/widgets/safe_network_image.dart';
import 'package:boardverse/features/leaderboard/domain/entities/leaderboard_entry_entity.dart';
import 'package:boardverse/features/leaderboard/domain/entities/leaderboard_kind.dart';
import 'package:boardverse/features/leaderboard/presentation/widgets/gamer_tier_color.dart';
import 'package:boardverse/features/leaderboard/presentation/widgets/leaderboard_metric.dart';

/// Podium top-3 theo Neo-Brutalism.
///
/// Layout: [Rank 2] [Rank 1 - cao hơn] [Rank 3]
///
/// - Rank 1 lớn nhất + gradient cam đậm + border 3px + medal gold
/// - Rank 2/3 cùng kích thước nhỏ hơn, medal silver/bronze
/// - Avatar lớn với border tier color
class LeaderboardPodium extends StatelessWidget {
  final List<LeaderboardEntryEntity> top;
  final LeaderboardKind kind;

  const LeaderboardPodium({
    super.key,
    required this.top,
    required this.kind,
  });

  @override
  Widget build(BuildContext context) {
    if (top.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);

    // Sắp xếp lại để đảm bảo thứ tự rank 2 - 1 - 3 (podium cổ điển)
    final rank2 = top.length > 1 ? top[1] : null;
    final rank1 = top.isNotEmpty ? top[0] : null;
    final rank3 = top.length > 2 ? top[2] : null;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: NeoBrutalismTheme.autoBox(
        context,
        backgroundColor: AppColors.accent.withValues(alpha: 0.12),
        borderColor: AppColors.accent,
        shadowColor: AppColors.accent.withValues(alpha: 0.25),
        bold: true,
        borderRadius: 20,
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (rank2 != null)
                Expanded(
                  child: _PodiumTile(
                    entry: rank2,
                    rank: 2,
                    height: 84,
                    kind: kind,
                  ),
                ),
              if (rank1 != null)
                Expanded(
                  child: _PodiumTile(
                    entry: rank1,
                    rank: 1,
                    height: 112,
                    kind: kind,
                    emphasized: true,
                  ),
                ),
              if (rank3 != null)
                Expanded(
                  child: _PodiumTile(
                    entry: rank3,
                    rank: 3,
                    height: 68,
                    kind: kind,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '🏆 Top 3 ${kind.label}',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.onSurfaceVariant,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _PodiumTile extends StatelessWidget {
  final LeaderboardEntryEntity entry;
  final int rank;
  final double height;
  final LeaderboardKind kind;
  final bool emphasized;

  const _PodiumTile({
    required this.entry,
    required this.rank,
    required this.height,
    required this.kind,
    this.emphasized = false,
  });

  Color _medalColor() {
    switch (rank) {
      case 1:
        return AppColors.eloGold;
      case 2:
        return AppColors.eloSilver;
      case 3:
        return AppColors.eloBronze;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final medalColor = _medalColor();
    final tierColor = entry.gamerTier.accentColor;
    final metric = LeaderboardMetric.resolve(entry, kind);
    final avatarSize = emphasized ? 84.0 : 64.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Stack avatar + medal rank pill
        Stack(
          alignment: Alignment.bottomCenter,
          clipBehavior: Clip.none,
          children: [
            Container(
              width: avatarSize,
              height: avatarSize,
              decoration: BoxDecoration(
                color: medalColor.withValues(alpha: 0.2),
                shape: BoxShape.circle,
                border: Border.all(color: tierColor, width: NeoBrutalismTheme.borderWidthBold),
              ),
              child: ClipOval(
                child: entry.avatarUrl != null && entry.avatarUrl!.isNotEmpty
                    ? SafeNetworkImage(
                        url: entry.avatarUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => _AvatarFallback(
                          text: entry.resolvedName,
                          color: tierColor,
                        ),
                      )
                    : _AvatarFallback(
                        text: entry.resolvedName,
                        color: tierColor,
                      ),
              ),
            ),
            Positioned(
              bottom: -8,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xs,
                  vertical: 2,
                ),
                decoration: NeoBrutalismTheme.brutalBox(
                  backgroundColor: medalColor,
                  borderColor: AppColors.border,
                  shadowColor: Colors.black.withValues(alpha: 0.4),
                  borderRadius: 10,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.workspace_premium, color: AppColors.white, size: 14),
                    const SizedBox(width: 2),
                    Text(
                      '#$rank',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: AppColors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          width: double.infinity,
          child: Text(
            entry.resolvedName,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(
          entry.gamerTier.label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: tierColor,
            fontWeight: FontWeight.w800,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: AppSpacing.xs),
        // Podium base — colored bar
        Container(
          width: double.infinity,
          height: height,
          decoration: BoxDecoration(
            color: medalColor.withValues(alpha: 0.18),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(10),
            ),
            border: Border.all(color: medalColor, width: 2),
          ),
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                metric.value,
                style: TextStyle(
                  fontSize: emphasized ? 20 : 16,
                  fontWeight: FontWeight.w900,
                  color: medalColor,
                ),
              ),
              Text(
                metric.label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  final String text;
  final Color color;
  const _AvatarFallback({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    final initial = text.isNotEmpty ? text.characters.first.toUpperCase() : '?';
    return Container(
      color: color.withValues(alpha: 0.2),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w900,
          color: color,
        ),
      ),
    );
  }
}
