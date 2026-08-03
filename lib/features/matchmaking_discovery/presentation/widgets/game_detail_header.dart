import 'package:flutter/material.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/safe_network_image.dart';
import '../../domain/entities/board_game_entity.dart';

/// Hero header cho trang chi tiết board game.
///
/// Layout:
///   - SliverAppBar: ảnh parallax + title tự động ở giữa khi scroll
///   - Game name: bên dưới ảnh (khi expanded)
///   - Category badge + Rating badge
///   - Quick stats row: players | time
class GameDetailHeader extends StatelessWidget {
  final BoardGameEntity game;

  const GameDetailHeader({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SliverMainAxisGroup(
      slivers: [
        // ── SliverAppBar: ảnh parallax + title ở giữa khi scroll ───────────
        SliverAppBar(
          expandedHeight: 240,
          pinned: true,
          stretch: true,
          backgroundColor: theme.colorScheme.surface,
          // Title tự động ở giữa khi scroll (Material 3 default)
          title: Text(
            game.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          titleTextStyle: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
          iconTheme: IconThemeData(color: theme.colorScheme.onSurface),
          actions: [
            IconButton(
              icon: const Icon(Icons.bookmark_border),
              onPressed: () {},
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            // Title khi expanded = hiển thị bên dưới ảnh
            titlePadding: const EdgeInsetsDirectional.only(
              start: AppSpacing.md,
              end: AppSpacing.md,
              bottom: AppSpacing.md + 40, // nhích xuống để tránh đè stats
            ),
            title: Text(
              game.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                shadows: [
                  Shadow(
                    offset: const Offset(0, 1),
                    blurRadius: 4,
                    color: Colors.black.withValues(alpha: 0.5),
                  ),
                ],
              ),
            ),
            background: Stack(
              fit: StackFit.expand,
              children: [
                SafeNetworkImage(
                  url: game.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: theme.colorScheme.surfaceContainerHighest,
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.extension,
                      size: 80,
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ),
                // Gradient bottom fade
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: 100,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.7),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Category + Rating + Stats bên dưới ảnh ───────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category + Rating badges
                Row(
                  children: [
                    if (game.category.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm + 2,
                          vertical: AppSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: AppRadius.radiusLgAll,
                        ),
                        child: Text(
                          game.category,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                    ],
                    if (game.rating > 0) _RatingBadge(rating: game.rating),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // Stats row
                _QuickStatsRow(
                  minPlayers: game.minPlayers,
                  maxPlayers: game.maxPlayers,
                  playTime: game.estimatedMinutes,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Badge rating với star.
class _RatingBadge extends StatelessWidget {
  final double rating;

  const _RatingBadge({required this.rating});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.tertiaryContainer,
        borderRadius: AppRadius.radiusLgAll,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.star_rounded,
            size: AppSpacing.md,
            color: theme.colorScheme.tertiary,
          ),
          const SizedBox(width: AppSpacing.xxs),
          Text(
            rating.toStringAsFixed(1),
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onTertiaryContainer,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

/// Stats row: players | time — 2 columns đơn giản.
class _QuickStatsRow extends StatelessWidget {
  final int minPlayers;
  final int maxPlayers;
  final int playTime;

  const _QuickStatsRow({
    required this.minPlayers,
    required this.maxPlayers,
    required this.playTime,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.md,
        horizontal: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: AppRadius.radiusMdAll,
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.people_rounded,
                  size: AppSpacing.lg,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  '$minPlayers-$maxPlayers người',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            height: 24,
            color: theme.colorScheme.outlineVariant,
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.schedule_rounded,
                  size: AppSpacing.lg,
                  color: theme.colorScheme.secondary,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  playTime > 0 ? '~$playTime phút' : '-',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
