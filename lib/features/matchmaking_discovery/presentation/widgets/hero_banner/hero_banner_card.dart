import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/widgets/safe_network_image.dart';
import '../../../domain/entities/board_game_entity.dart';
import 'animated_gradient_border.dart';

/// Single hero card on the carousel — animated gradient border + parallax
/// handled by parent (parallax is applied via Transform.scale in
/// [HeroBannerCarousel]).
class HeroBannerCard extends StatefulWidget {
  final BoardGameEntity game;
  final String? badgeText;
  final VoidCallback onTap;

  const HeroBannerCard({
    super.key,
    required this.game,
    required this.badgeText,
    required this.onTap,
  });

  @override
  State<HeroBannerCard> createState() => _HeroBannerCardState();
}

class _HeroBannerCardState extends State<HeroBannerCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressCtrl;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0,
      upperBound: 1,
    );
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

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
          final scale = 1 - (_pressCtrl.value * 0.03);
          return Transform.scale(scale: scale, child: child);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          child: Stack(
            children: [
              // Animated gradient border
              AnimatedGradientBorder(
                borderRadius: AppRadius.radiusLgAll,
                child: ClipRRect(
                  borderRadius: AppRadius.radiusLgAll,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      SafeNetworkImage(
                        url: widget.game.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, st) => Container(
                          color: theme.colorScheme.surfaceContainerHighest,
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.extension,
                            size: AppSpacing.huge,
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ),
                      // Gradient overlay để text dễ đọc
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              AppColors.black.withValues(alpha: 0.75),
                            ],
                            stops: const [0.45, 1.0],
                          ),
                        ),
                      ),
                      // Text content
                      Positioned(
                        left: AppSpacing.md,
                        right: AppSpacing.md,
                        bottom: AppSpacing.md,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (widget.badgeText != null)
                              Container(
                                margin: const EdgeInsets.only(
                                  bottom: AppSpacing.xs,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.xs,
                                  vertical: AppSpacing.xxs,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.accent,
                                  borderRadius: AppRadius.radiusSmAll,
                                ),
                                child: Text(
                                  widget.badgeText!,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: AppColors.black,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ),
                            Text(
                              widget.game.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                shadows: [
                                  Shadow(
                                    color: AppColors.black.withValues(
                                      alpha: 0.5,
                                    ),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xxs),
                            Row(
                              children: [
                                if (widget.game.category.isNotEmpty) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.xs,
                                      vertical: AppSpacing.xxs,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: 0.18,
                                      ),
                                      borderRadius: AppRadius.radiusFullAll,
                                    ),
                                    child: Text(
                                      widget.game.category,
                                      style: theme.textTheme.labelSmall?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.xs),
                                ],
                                if (widget.game.rating > 0)
                                  Icon(
                                    Icons.star,
                                    size: AppSpacing.md,
                                    color: AppColors.warning,
                                  ),
                                if (widget.game.rating > 0) ...[
                                  const SizedBox(width: AppSpacing.xxs),
                                  Text(
                                    widget.game.rating.toStringAsFixed(1),
                                    style: theme.textTheme.labelMedium?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
