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

/// Neo-Brutalism tile cho leaderboard row.
///
/// Layout:
///   [Rank circle]  [Avatar neo]  [Name + Tier badge]  [Metric value]
///
/// - Rank circle: gold/silver/bronze cho top 3, plain border cho >3
/// - Avatar: 56px với border 3px màu tier (neo avatar)
/// - Tier badge: pill đậm với màu tier + text trắng
/// - Metric: số lớn với accent color theo kind + label nhỏ dưới
class LeaderboardRowTile extends StatefulWidget {
  final LeaderboardEntryEntity entry;
  final LeaderboardKind kind;
  final bool showUserRankHint;

  const LeaderboardRowTile({
    super.key,
    required this.entry,
    required this.kind,
    this.showUserRankHint = false,
  });

  @override
  State<LeaderboardRowTile> createState() => _LeaderboardRowTileState();
}

class _LeaderboardRowTileState extends State<LeaderboardRowTile> {
  bool _isPressed = false;

  void _setPressed(bool v) {
    if (_isPressed != v) setState(() => _isPressed = v);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final metric = LeaderboardMetric.resolve(widget.entry, widget.kind);
    final isTop3 = widget.entry.rank <= 3;
    final medalColor = AppColors.getMedalColor(widget.entry.rank);
    final tierColor = widget.entry.gamerTier.accentColor;

    final cardBg = widget.showUserRankHint
        ? AppColors.primary.withValues(alpha: 0.12)
        : (isTop3
            ? AppColors.accent.withValues(alpha: 0.08)
            : null);

    final borderColor = widget.showUserRankHint
        ? AppColors.primary
        : (isTop3 ? AppColors.accentDark : null);

    return GestureDetector(
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      child: AnimatedScale(
        scale: _isPressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 80),
        curve: Curves.easeOut,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: NeoBrutalismTheme.autoBox(
            context,
            backgroundColor: cardBg,
            borderColor: borderColor,
            shadowColor: (widget.showUserRankHint
                    ? AppColors.primary
                    : (isTop3 ? AppColors.accent : AppColors.primary))
                .withValues(alpha: 0.18),
            bold: widget.showUserRankHint || isTop3,
            borderRadius: 14,
          ),
          child: Row(
            children: [
              _RankBadge(rank: widget.entry.rank, medalColor: medalColor),
              const SizedBox(width: AppSpacing.md),
              _NeoAvatar(
                avatarUrl: widget.entry.avatarUrl,
                fallbackText: widget.entry.resolvedName,
                borderColor: tierColor,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.entry.resolvedName,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Row(
                      children: [
                        TierBadge(tier: widget.entry.gamerTier),
                        if (widget.entry.level != null) ...[
                          const SizedBox(width: AppSpacing.xs),
                          Flexible(
                            child: Text(
                              'Lv.${widget.entry.level}',
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              _MetricColumn(metric: metric),
            ],
          ),
        ),
      ),
    );
  }
}

/// Rank badge — circle neo-brutalism với màu medal cho top 3, plain
/// border cho các rank còn lại.
class _RankBadge extends StatelessWidget {
  final int rank;
  final Color medalColor;

  const _RankBadge({required this.rank, required this.medalColor});

  @override
  Widget build(BuildContext context) {
    final isTop3 = rank <= 3;
    return Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isTop3 ? medalColor : Colors.transparent,
        shape: BoxShape.circle,
        border: Border.all(
          color: isTop3 ? AppColors.border : AppColors.textTertiary,
          width: isTop3 ? NeoBrutalismTheme.borderWidthBold : NeoBrutalismTheme.borderWidth,
        ),
        boxShadow: isTop3
            ? NeoBrutalismTheme.lightShadow(
                shadowColor: medalColor.withValues(alpha: 0.4),
              )
            : null,
      ),
      child: isTop3
          ? Icon(Icons.workspace_premium, color: AppColors.white, size: 22)
          : Text(
              '$rank',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
              ),
            ),
    );
  }
}

/// Avatar neo-brutalism với border theo tier color. Dùng
/// `SafeNetworkImage` cho remote URL, fallback initials nếu lỗi/rỗng.
class _NeoAvatar extends StatelessWidget {
  final String? avatarUrl;
  final String fallbackText;
  final Color borderColor;

  const _NeoAvatar({
    required this.avatarUrl,
    required this.fallbackText,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final initial = fallbackText.isNotEmpty
        ? fallbackText.characters.first.toUpperCase()
        : '?';
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: borderColor.withValues(alpha: 0.18),
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: NeoBrutalismTheme.borderWidthBold),
      ),
      child: ClipOval(
        child: avatarUrl != null && avatarUrl!.isNotEmpty
            ? SafeNetworkImage(
                url: avatarUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _Initials(initial: initial, color: borderColor),
              )
            : _Initials(initial: initial, color: borderColor),
      ),
    );
  }
}

class _Initials extends StatelessWidget {
  final String initial;
  final Color color;

  const _Initials({required this.initial, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color.withValues(alpha: 0.2),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w900,
          color: color,
        ),
      ),
    );
  }
}

/// Cột metric ở cuối row — số lớn + label nhỏ phía dưới, tone accent
/// theo `LeaderboardKind`.
class _MetricColumn extends StatelessWidget {
  final LeaderboardMetric metric;

  const _MetricColumn({required this.metric});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
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
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
