import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/neo_brutalism_theme.dart';
import '../../domain/entities/recommended_board_game_entity.dart';

/// Card hiển thị một board game được gợi ý.
///
/// Layout dọc 2 phần:
/// - TOP: Thumbnail lớn (full-width) + score badge overlay ở góc trên-phải
/// - BOTTOM: Info (name, weight, players, time, match reasons chips)
///
/// Style: neo-brutalism border 3px, hard shadow, vibrant badges.
class RecommendedGameCard extends StatelessWidget {
  final RecommendedBoardGameEntity game;
  final Widget? trailing;
  final VoidCallback? onTap;

  const RecommendedGameCard({
    super.key,
    required this.game,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return _CardWithPress(
      onTap: onTap,
      child: Container(
        decoration: NeoBrutalismTheme.autoBox(
          context,
          backgroundColor:
              isDark ? AppColors.surfaceDark : AppColors.surface,
          borderRadius: 18,
          bold: true,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── TOP: Image + score overlay + rank badge ─────────────
            Stack(
              children: [
                _Thumbnail(
                  imageUrl: game.imageUrl,
                  height: 132,
                  isDark: isDark,
                ),
                Positioned(
                  top: AppSpacing.xs,
                  right: AppSpacing.xs,
                  child: _ScoreBadge(score: game.score),
                ),
                if (game.weight != null)
                  Positioned(
                    top: AppSpacing.xs,
                    left: AppSpacing.xs,
                    child: _WeightBadge(weight: game.weight!),
                  ),
              ],
            ),
            // ─── BOTTOM: Info ───────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Game name
                  Text(
                    game.name,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      height: 1.2,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimary,
                      letterSpacing: -0.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  // Meta row (players + time)
                  Row(
                    children: [
                      _MetaIcon(
                        icon: Icons.people_rounded,
                        text: game.playerRangeDisplay,
                        isDark: isDark,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Container(
                        width: 3,
                        height: 3,
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.textTertiaryDark
                              : AppColors.textTertiary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      _MetaIcon(
                        icon: Icons.timer_outlined,
                        text: '${game.playTimeMinutes} phút',
                        isDark: isDark,
                      ),
                    ],
                  ),
                  // Match reasons
                  if (game.matchReasons.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children:
                          game.matchReasons.take(2).map((reason) {
                        return _ReasonChip(text: reason);
                      }).toList(),
                    ),
                  ],
                  if (trailing != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    trailing!,
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helper: Card with press animation
// ─────────────────────────────────────────────────────────────────────────────

class _CardWithPress extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const _CardWithPress({required this.child, this.onTap});

  @override
  State<_CardWithPress> createState() => _CardWithPressState();
}

class _CardWithPressState extends State<_CardWithPress> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: widget.child,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helper: Thumbnail
// ─────────────────────────────────────────────────────────────────────────────

class _Thumbnail extends StatelessWidget {
  final String? imageUrl;
  final double height;
  final bool isDark;

  const _Thumbnail({
    required this.imageUrl,
    required this.height,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final radius = const BorderRadius.vertical(top: Radius.circular(16));

    return ClipRRect(
      borderRadius: radius,
      child: SizedBox(
        width: double.infinity,
        height: height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Base background
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [
                          AppColors.surfaceContainerDark,
                          AppColors.surfaceElevatedDark,
                        ]
                      : [
                          AppColors.surfaceVariant,
                          AppColors.background,
                        ],
                ),
              ),
            ),
            if (imageUrl != null && imageUrl!.isNotEmpty)
              Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const _PlaceholderImage(),
              )
            else
              const _PlaceholderImage(),
            // Bottom subtle gradient for badge contrast
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.08),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.35],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaceholderImage extends StatelessWidget {
  const _PlaceholderImage();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  AppColors.surfaceContainerDark,
                  AppColors.surfaceElevatedDark,
                ]
              : [
                  AppColors.primaryLight.withValues(alpha: 0.25),
                  AppColors.accentLight.withValues(alpha: 0.25),
                ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.sports_esports_rounded,
          size: 48,
          color: isDark
              ? AppColors.textTertiaryDark
              : AppColors.primary.withValues(alpha: 0.45),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helper: Score badge (top-right of thumbnail)
// ─────────────────────────────────────────────────────────────────────────────

class _ScoreBadge extends StatelessWidget {
  final double score;

  const _ScoreBadge({required this.score});

  @override
  Widget build(BuildContext context) {
    final color = _scoreColor(score);
    final tier = _scoreTier(score);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs + 1,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border, width: 2),
        boxShadow: NeoBrutalismTheme.lightShadow(
          shadowColor: color.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            score.toStringAsFixed(0),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              height: 1.0,
              letterSpacing: -0.5,
            ),
          ),
          Text(
            tier,
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w900,
              color: Colors.white.withValues(alpha: 0.95),
              height: 1.0,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }

  Color _scoreColor(double s) {
    if (s >= 80) return AppColors.success;
    if (s >= 65) return AppColors.warning;
    if (s >= 50) return AppColors.accentDark;
    return AppColors.textTertiary;
  }

  String _scoreTier(double s) {
    if (s >= 80) return 'TỐT';
    if (s >= 65) return 'OK';
    if (s >= 50) return 'TẠM';
    return 'YẾU';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helper: Weight badge (top-left of thumbnail)
// ─────────────────────────────────────────────────────────────────────────────

class _WeightBadge extends StatelessWidget {
  final double weight;

  const _WeightBadge({required this.weight});

  @override
  Widget build(BuildContext context) {
    final label = _weightLabel(weight);
    final color = _weightColor(weight);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: 2),
        boxShadow: NeoBrutalismTheme.lightShadow(
          shadowColor: Colors.black.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.scale_rounded, size: 10, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: color,
              letterSpacing: 0.3,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  String _weightLabel(double w) {
    if (w <= 1.99) return 'NHẸ';
    if (w <= 2.99) return 'TB NHẸ';
    if (w <= 3.49) return 'TRUNG BÌNH';
    if (w <= 3.99) return 'TB NẶNG';
    return 'NẶNG';
  }

  Color _weightColor(double w) {
    if (w <= 1.99) return const Color(0xFF4CAF50);
    if (w <= 2.99) return const Color(0xFF8BC34A);
    if (w <= 3.49) return const Color(0xFFFF9800);
    if (w <= 3.99) return const Color(0xFFFF5722);
    return const Color(0xFFF44336);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helper: Meta icon (players + time)
// ─────────────────────────────────────────────────────────────────────────────

class _MetaIcon extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool isDark;

  const _MetaIcon({
    required this.icon,
    required this.text,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondary;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 3),
        Text(
          text,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: color,
            letterSpacing: 0.1,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helper: Match reason chip
// ─────────────────────────────────────────────────────────────────────────────

class _ReasonChip extends StatelessWidget {
  final String text;

  const _ReasonChip({required this.text});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.success.withValues(alpha: 0.15)
            : AppColors.success.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: AppColors.success.withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle_rounded,
            size: 10,
            color: AppColors.success,
          ),
          const SizedBox(width: 3),
          Text(
            text,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: isDark
                  ? AppColors.successLight
                  : AppColors.successDark,
              height: 1.0,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
