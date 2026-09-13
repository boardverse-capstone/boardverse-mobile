import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/neo_brutalism_theme.dart';
import '../../../../core/widgets/safe_network_image.dart';
import '../../domain/entities/board_game_entity.dart';

/// Neo-brutalism hero SliverAppBar cho trang chi tiết board game.
///
/// TRẺN: Đặt trực tiếp trong `CustomScrollView.slivers` (KHÔNG lồng trong
/// `SliverMainAxisGroup`) để `pinned: true` hoạt động đúng. Khi SliverAppBar
/// bị wrap trong SliverMainAxisGroup, pinned bị ignore hoặc hoạt động sai.
/// Phần category/rating/stats bên dưới để riêng trong `GameDetailMetaInfo`.
class GameDetailSliverAppBar extends StatefulWidget {
  final BoardGameEntity game;

  const GameDetailSliverAppBar({super.key, required this.game});

  @override
  State<GameDetailSliverAppBar> createState() => _GameDetailSliverAppBarState();
}

class _GameDetailSliverAppBarState extends State<GameDetailSliverAppBar> {
  bool _isBookmarked = false;

  void _toggleBookmark() {
    setState(() => _isBookmarked = !_isBookmarked);
    HapticFeedback.mediumImpact();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // SliverAppBar ở đây — pinned=true bắt buộc phải nằm trực tiếp
    // trong CustomScrollView.slivers, không lồng trong SliverMainAxisGroup.
    return SliverAppBar(
      expandedHeight: 240,
      pinned: true,
      stretch: true,
      scrolledUnderElevation: 4,
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surface,
      surfaceTintColor: Colors.transparent,
      shadowColor: AppColors.black.withValues(alpha: 0.15),
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
      // Border dưới AppBar — đảm bảo user luôn phân biệt được
      // AppBar với body content khi scroll.
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isDark ? AppColors.borderDark : AppColors.border,
                width: NeoBrutalismTheme.borderWidth,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Wrapper giữ backward-compat: gộp SliverAppBar + meta info vào 1
/// SliverMainAxisGroup. Dùng trực tiếp trong CustomScrollView.slivers.
class GameDetailHeader extends StatelessWidget {
  final BoardGameEntity game;

  const GameDetailHeader({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return SliverMainAxisGroup(
      slivers: [
        // SliverAppBar — đặt trực tiếp trong group (không lồng thêm),
        // pinned=true vẫn hoạt động vì group nằm trực tiếp trong
        // CustomScrollView.slivers, không phải lồng trong group khác.
        SliverDetailAppBar(game: game),
        // Category + rating + stats — scroll bình thường.
        GameDetailMetaInfo(game: game),
      ],
    );
  }
}

/// SliverAppBar cho game detail — tách riêng để dùng được trong
/// CustomScrollView.slivers mà không qua SliverMainAxisGroup trung gian.
class SliverDetailAppBar extends StatefulWidget {
  final BoardGameEntity game;

  const SliverDetailAppBar({super.key, required this.game});

  @override
  State<SliverDetailAppBar> createState() => _SliverDetailAppBarState();
}

class _SliverDetailAppBarState extends State<SliverDetailAppBar> {
  bool _isBookmarked = false;

  void _toggleBookmark() {
    setState(() => _isBookmarked = !_isBookmarked);
    HapticFeedback.mediumImpact();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SliverAppBar(
      expandedHeight: 240,
      pinned: true,
      stretch: true,
      scrolledUnderElevation: 4,
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surface,
      surfaceTintColor: Colors.transparent,
      shadowColor: AppColors.black.withValues(alpha: 0.15),
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
          border: Border.all(color: AppColors.black, width: 2),
          boxShadow: const [
            BoxShadow(
              color: AppColors.black,
              blurRadius: 0,
              offset: Offset(2, 2),
            ),
          ],
        ),
        child: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.black, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.all(AppSpacing.xs),
          decoration: BoxDecoration(
            color: AppColors.white,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.black, width: 2),
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
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isDark ? AppColors.borderDark : AppColors.border,
                width: NeoBrutalismTheme.borderWidth,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Phần category badge + rating + quick stats row — nằm ngay dưới
/// SliverAppBar, bọc trong SliverMainAxisGroup để giữ scroll behavior.
class GameDetailMetaInfo extends StatelessWidget {
  final BoardGameEntity game;

  const GameDetailMetaInfo({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SliverToBoxAdapter(
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
                if (game.category.isNotEmpty) ...[
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
                      game.category.toUpperCase(),
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
                if (game.rating > 0)
                  _RatingBadge(rating: game.rating),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            _QuickStatsRow(
              minPlayers: game.minPlayers,
              maxPlayers: game.maxPlayers,
              playTime: game.estimatedMinutes,
            ),
          ],
        ),
      ),
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

  String get _playerRangeText =>
      minPlayers == maxPlayers ? '$minPlayers' : '$minPlayers-$maxPlayers';

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
                  _playerRangeText,
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
