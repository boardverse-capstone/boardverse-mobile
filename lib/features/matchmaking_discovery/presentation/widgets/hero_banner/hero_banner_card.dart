import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/neo_brutalism_theme.dart';
import '../../../../../core/widgets/safe_network_image.dart';
import '../../../domain/entities/board_game_entity.dart';

/// Neo-brutalism Hero banner card.
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
      duration: const Duration(milliseconds: 100),
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
    final isDark = theme.brightness == Brightness.dark;
    final isPressed = _pressCtrl.isAnimating && _pressCtrl.value > 0.5;

    return GestureDetector(
      onTapDown: (_) => _pressCtrl.forward(),
      onTapUp: (_) => _pressCtrl.reverse(),
      onTapCancel: () => _pressCtrl.reverse(),
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _pressCtrl,
        builder: (context, child) {
          return Transform.scale(
            scale: 1 - (_pressCtrl.value * 0.03),
            child: Transform.translate(
              offset: isPressed ? const Offset(3, 3) : Offset.zero,
              child: child,
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          child: Stack(
            children: [
              // Hard shadow offset
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.black,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),

              // Main container
              Container(
                margin: const EdgeInsets.only(right: 3, bottom: 3),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.surfaceDark
                      : AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark ? AppColors.borderDark : AppColors.border,
                    width: NeoBrutalismTheme.borderWidthBold,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
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
                      // Gradient overlay
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              AppColors.black.withValues(alpha: 0.8),
                            ],
                            stops: const [0.4, 1.0],
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
                                  horizontal: AppSpacing.xs + 2,
                                  vertical: AppSpacing.xxs + 1,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.accent,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: AppColors.black,
                                    width: 2,
                                  ),
                                ),
                                child: Text(
                                  widget.badgeText!.toUpperCase(),
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: AppColors.black,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),
                            Text(
                              widget.game.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                color: AppColors.white,
                                fontWeight: FontWeight.w900,
                                shadows: [
                                  Shadow(
                                    color: AppColors.black.withValues(alpha: 0.6),
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
                                      color: AppColors.white
                                          .withValues(alpha: 0.25),
                                      borderRadius: AppRadius.radiusFullAll,
                                      border: Border.all(
                                        color: AppColors.white
                                            .withValues(alpha: 0.4),
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      widget.game.category,
                                      style:
                                          theme.textTheme.labelSmall?.copyWith(
                                        color: AppColors.white,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.xs),
                                ],
                                if (widget.game.rating > 0) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.xs,
                                      vertical: AppSpacing.xxs,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.warning,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.star,
                                          size: AppSpacing.sm,
                                          color: AppColors.black,
                                        ),
                                        const SizedBox(width: 2),
                                        Text(
                                          widget.game.rating.toStringAsFixed(1),
                                          style: theme.textTheme.labelSmall
                                              ?.copyWith(
                                            color: AppColors.black,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ],
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
