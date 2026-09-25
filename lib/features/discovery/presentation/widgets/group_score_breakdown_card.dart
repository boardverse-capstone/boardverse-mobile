import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/neo_brutalism_theme.dart';
import '../../domain/entities/group_board_game_entity.dart';

/// Card hiển thị group game với breakdown theo từng sub-group.
///
/// Layout tương tự RecommendedGameCard:
/// - TOP: Thumbnail + score overlay
/// - MIDDLE: Game info (name, players, time, weight)
/// - BOTTOM: Per-sub-group score breakdown (mỗi nhóm người chơi 1 chip)
class GroupScoreBreakdownCard extends StatelessWidget {
  final GroupBoardGameEntity game;
  final VoidCallback? onTap;

  const GroupScoreBreakdownCard({
    super.key,
    required this.game,
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
            // ─── TOP: Image + score overlay + weight badge ────────────
            Stack(
              children: [
                _Thumbnail(
                  imageUrl: game.imageUrl,
                  height: 120,
                  isDark: isDark,
                ),
                Positioned(
                  top: AppSpacing.xs,
                  right: AppSpacing.xs,
                  child: _ScoreBadge(score: game.aggregateScore),
                ),
                if (game.weight != null)
                  Positioned(
                    top: AppSpacing.xs,
                    left: AppSpacing.xs,
                    child: _WeightBadge(weight: game.weight!),
                  ),
              ],
            ),
            // ─── MIDDLE: Info ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                  // Meta row
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
                ],
              ),
            ),

            // ─── BOTTOM: Sub-group breakdown ──────────────────────────
            if (game.subGroupScores.isNotEmpty)
              Container(
                margin: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  0,
                  AppSpacing.md,
                  AppSpacing.md,
                ),
                padding: const EdgeInsets.all(AppSpacing.sm + 2),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.surfaceContainerDark
                      : AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark
                        ? AppColors.borderDark
                        : AppColors.border,
                    width: 1.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.groups_rounded,
                          size: 12,
                          color: AppColors.secondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'PHÙ HỢP TỪNG NHÓM',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondary,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: game.subGroupScores.map((sg) {
                        final color = _scoreColor(sg.score);
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xs + 2,
                            vertical: AppSpacing.xxs + 1,
                          ),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: color.withValues(alpha: 0.4),
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.people_outline_rounded,
                                size: 11,
                                color: color,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                '${sg.playerCount} người',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: color,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: color,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  sg.score.toStringAsFixed(0),
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    height: 1.0,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _scoreColor(double score) {
    if (score >= 80) return AppColors.success;
    if (score >= 65) return AppColors.warning;
    if (score >= 50) return AppColors.accentDark;
    return AppColors.textTertiary;
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
                  AppColors.secondaryLight.withValues(alpha: 0.3),
                  AppColors.accentLight.withValues(alpha: 0.3),
                ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.sports_esports_rounded,
          size: 44,
          color: isDark
              ? AppColors.textTertiaryDark
              : AppColors.secondary.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helper: Score badge
// ─────────────────────────────────────────────────────────────────────────────

class _ScoreBadge extends StatelessWidget {
  final double score;

  const _ScoreBadge({required this.score});

  @override
  Widget build(BuildContext context) {
    final color = _scoreColor(score);

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
            'TỔNG',
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
}

// ─────────────────────────────────────────────────────────────────────────────
// Helper: Weight badge
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
// Helper: Meta icon
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
