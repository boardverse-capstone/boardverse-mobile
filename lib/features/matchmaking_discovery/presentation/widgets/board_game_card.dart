import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/safe_network_image.dart';
import '../../domain/entities/board_game_entity.dart';

/// Card game hiển thị trong danh sách khám phá — pattern "Magazine Cover":
///
/// - Hero image chiếm trọn card (full bleed), ảnh được phóng to nên không
///   che hết artwork.
/// - Dưới ảnh là dark info bar (gradient từ trong suốt sang đen) chứa toàn
///   bộ text + meta — chữ trắng luôn đọc được bất kể ảnh nền.
/// - Thông tin đầy đủ: tên game, category chip, meta (số người + thời gian).
/// - Badge "HOT" và rating nổi trên ảnh ở 2 góc trên, không che artwork.
/// - Tap-scale 4% khi nhấn.
class BoardGameCard extends StatefulWidget {
  final BoardGameEntity game;
  final VoidCallback? onTap;

  /// Đánh dấu game "Hot" — hiện badge góc trên trái. Mặc định dựa trên
  /// rating >= 4.5 hoặc category Party.
  final bool? forceHotBadge;

  const BoardGameCard({
    super.key,
    required this.game,
    this.onTap,
    this.forceHotBadge,
  });

  @override
  State<BoardGameCard> createState() => _BoardGameCardState();
}

class _BoardGameCardState extends State<BoardGameCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressCtrl;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
      lowerBound: 0,
      upperBound: 1,
    );
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  bool get _isHot =>
      widget.forceHotBadge ??
      (widget.game.rating >= 4.5 || widget.game.category == 'Party');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTapDown: (_) => _pressCtrl.forward(),
      onTapUp: (_) => _pressCtrl.reverse(),
      onTapCancel: () => _pressCtrl.reverse(),
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _pressCtrl,
        builder: (context, child) {
          final scale = 1 - (_pressCtrl.value * 0.04);
          return Transform.scale(scale: scale, child: child);
        },
        child: ClipRRect(
          borderRadius: AppRadius.radiusMdAll,
          child: Material(
            color: AppColors.black,
            child: InkWell(
              splashColor: Colors.white.withValues(alpha: 0.12),
              highlightColor: Colors.white.withValues(alpha: 0.06),
              child: AspectRatio(
                aspectRatio: 4 / 5,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // ─── 1. Ảnh full bleed ───
                    SafeNetworkImage(
                      url: widget.game.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: theme.colorScheme.surfaceContainerHighest,
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.extension,
                          size: AppSpacing.huge,
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ),

                    // ─── 2. Subtle top gradient (để badge / rating nổi) ───
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0x55000000),
                            Color(0x00000000),
                          ],
                          stops: [0.0, 0.35],
                        ),
                      ),
                    ),

                    // ─── 3. Badge HOT + Rating nổi ───
                    if (_isHot)
                      const Positioned(
                        top: AppSpacing.sm,
                        left: AppSpacing.sm,
                        child: _BadgePill(
                          label: 'HOT',
                          color: AppColors.error,
                          foreground: AppColors.white,
                          icon: Icons.local_fire_department,
                        ),
                      ),
                    if (widget.game.rating > 0)
                      Positioned(
                        top: AppSpacing.sm,
                        right: AppSpacing.sm,
                        child: _BadgePill(
                          label: widget.game.rating.toStringAsFixed(1),
                          color: AppColors.white.withValues(alpha: 0.95),
                          foreground: AppColors.black,
                          icon: Icons.star,
                          iconColor: AppColors.warning,
                        ),
                      ),

                    // ─── 4. Dark info bar ở dưới (gradient → đen) ───
                    const Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Color(0x00000000),
                              Color(0x33000000),
                              Color(0xCC000000),
                              Color(0xEE000000),
                            ],
                            stops: [0.45, 0.65, 0.85, 1.0],
                          ),
                        ),
                      ),
                    ),

                    // ─── 5. Text content + meta trên dark bar ───
                    Positioned(
                      left: AppSpacing.md,
                      right: AppSpacing.md,
                      bottom: AppSpacing.md,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.game.category.isNotEmpty)
                            Container(
                              margin: const EdgeInsets.only(
                                bottom: AppSpacing.xs,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.xs + 2,
                                vertical: AppSpacing.xxs + 1,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.white.withValues(alpha: 0.18),
                                borderRadius: AppRadius.radiusFullAll,
                                border: Border.all(
                                  color: AppColors.white.withValues(
                                    alpha: 0.25,
                                  ),
                                  width: 0.5,
                                ),
                              ),
                              child: Text(
                                widget.game.category,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: AppColors.white,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                          Text(
                            widget.game.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: AppColors.white,
                              fontWeight: FontWeight.w800,
                              height: 1.2,
                              shadows: [
                                Shadow(
                                  color: AppColors.black.withValues(
                                    alpha: 0.6,
                                  ),
                                  blurRadius: 6,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Row(
                            children: [
                              _MetaPill(
                                icon: Icons.people_alt,
                                text:
                                    '${widget.game.minPlayers}-${widget.game.maxPlayers}',
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              _MetaPill(
                                icon: Icons.schedule,
                                text: '~${widget.game.estimatedMinutes}p',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Pill nhỏ gồm icon + text — dùng cho meta (số người, thời gian) trên
/// dark info bar. Chữ trắng trên nền đen nên luôn đọc được.
class _MetaPill extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MetaPill({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: AppSpacing.sm + 1, color: AppColors.white),
        const SizedBox(width: AppSpacing.xxs + 1),
        Text(
          text,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}

/// Badge pill — dùng cho "HOT" và rating. Khác `_MetaPill` ở chỗ có nền
/// đặc và bo góc pill hoàn toàn.
class _BadgePill extends StatelessWidget {
  final String label;
  final Color color;
  final Color foreground;
  final IconData icon;
  final Color? iconColor;

  const _BadgePill({
    required this.label,
    required this.color,
    required this.foreground,
    required this.icon,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs + 1,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: AppRadius.radiusFullAll,
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.18),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: AppSpacing.sm + 1,
            color: iconColor ?? foreground,
          ),
          const SizedBox(width: AppSpacing.xxs),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                ),
          ),
        ],
      ),
    );
  }
}