import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/neo_brutalism_theme.dart';
import '../../../../core/widgets/safe_network_image.dart';
import '../../domain/entities/board_game_entity.dart';

/// Neo-brutalism Hero header cho trang chi tiết board game.
class GameDetailHeader extends StatefulWidget {
  final BoardGameEntity game;

  const GameDetailHeader({super.key, required this.game});

  @override
  State<GameDetailHeader> createState() => _GameDetailHeaderState();
}

class _GameDetailHeaderState extends State<GameDetailHeader> {
  bool _isBookmarked = false;

  void _toggleBookmark() {
    setState(() => _isBookmarked = !_isBookmarked);
    HapticFeedback.mediumImpact();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SliverMainAxisGroup(
      slivers: [
        // SliverAppBar với neo-brutalism back button
        SliverAppBar(
          expandedHeight: 240,
          pinned: true,
          stretch: true,
          backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surface,
          title: Text(
            widget.game.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          titleTextStyle: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: isDark
                ? AppColors.textPrimaryDark
                : AppColors.textPrimary,
          ),
          leading: Container(
            margin: const EdgeInsets.all(AppSpacing.xs),
            decoration: BoxDecoration(
              color: AppColors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.black,
                width: 2,
              ),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.black,
                  blurRadius: 0,
                  offset: Offset(2, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back,
                color: AppColors.black,
                size: 18,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          actions: [
            Container(
              margin: const EdgeInsets.all(AppSpacing.xs),
              decoration: BoxDecoration(
                color: AppColors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.black,
                  width: 2,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.black,
                    blurRadius: 0,
                    offset: Offset(2, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: Icon(
                  _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                  color: AppColors.black,
                  size: 18,
                ),
                onPressed: _toggleBookmark,
              ),
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            titlePadding: const EdgeInsetsDirectional.only(
              start: AppSpacing.md,
              end: AppSpacing.md,
              bottom: AppSpacing.md + 40,
            ),
            title: Text(
              widget.game.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: AppColors.white,
                shadows: [
                  Shadow(
                    offset: Offset(0, 1),
                    blurRadius: 4,
                    color: AppColors.black,
                  ),
                ],
              ),
            ),
            background: Stack(
              fit: StackFit.expand,
              children: [
                SafeNetworkImage(
                  url: widget.game.imageUrl,
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
                          AppColors.black.withValues(alpha: 0.7),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Category + Rating + Stats
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
                Row(
                  children: [
                    if (widget.game.category.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm + 2,
                          vertical: AppSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isDark
                                ? AppColors.borderDark
                                : AppColors.border,
                            width: 2,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: AppColors.black,
                              blurRadius: 0,
                              offset: Offset(2, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          widget.game.category.toUpperCase(),
                          style: const TextStyle(
                            color: AppColors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 11,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                    ],
                    if (widget.game.rating > 0)
                      _RatingBadge(rating: widget.game.rating),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                _QuickStatsRow(
                  minPlayers: widget.game.minPlayers,
                  maxPlayers: widget.game.maxPlayers,
                  playTime: widget.game.estimatedMinutes,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _RatingBadge extends StatelessWidget {
  final double rating;

  const _RatingBadge({required this.rating});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.warning,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.black,
          width: 2,
        ),
        boxShadow: const [
          BoxShadow(
            color: AppColors.black,
            blurRadius: 0,
            offset: Offset(2, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.star_rounded,
            size: AppSpacing.md,
            color: AppColors.black,
          ),
          const SizedBox(width: AppSpacing.xxs),
          Text(
            rating.toStringAsFixed(1),
            style: const TextStyle(
              color: AppColors.black,
              fontWeight: FontWeight.w900,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

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
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.md,
        horizontal: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.border,
          width: NeoBrutalismTheme.borderWidth,
        ),
        boxShadow: NeoBrutalismTheme.lightShadow(
          shadowColor: AppColors.black.withValues(alpha: 0.06),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.people_rounded,
                    size: AppSpacing.md,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  '$minPlayers-$maxPlayers',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 2,
            height: 24,
            color: isDark ? AppColors.borderDark : AppColors.border,
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.schedule_rounded,
                    size: AppSpacing.md,
                    color: AppColors.secondary,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  playTime > 0 ? '~$playTime phút' : '-',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
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
