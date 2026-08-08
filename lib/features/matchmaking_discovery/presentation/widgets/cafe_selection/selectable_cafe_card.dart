import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/neo_brutalism_theme.dart';
import '../../../domain/entities/cafe_entity.dart';
import 'cafe_chip.dart';

/// Neo-brutalism Cafe card có thể chọn.
class SelectableCafeCard extends StatefulWidget {
  final CafeEntity cafe;
  final VoidCallback onTap;

  const SelectableCafeCard({
    super.key,
    required this.cafe,
    required this.onTap,
  });

  @override
  State<SelectableCafeCard> createState() => _SelectableCafeCardState();
}

class _SelectableCafeCardState extends State<SelectableCafeCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressCtrl;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      duration: const Duration(milliseconds: 80),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _pressCtrl, curve: Curves.easeOut),
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

    final distanceLabel = widget.cafe.distanceMeters < 1000
        ? '${widget.cafe.distanceMeters.toStringAsFixed(0)} m'
        : '${(widget.cafe.distanceMeters / 1000).toStringAsFixed(1)} km';

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Transform.translate(
            offset: isPressed ? const Offset(2, 2) : Offset.zero,
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onTapDown: (_) {
          _pressCtrl.forward();
          HapticFeedback.lightImpact();
        },
        onTapUp: (_) => _pressCtrl.reverse(),
        onTapCancel: () => _pressCtrl.reverse(),
        onTap: widget.onTap,
        child: Container(
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
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.sm + 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color:
                          isDark ? AppColors.borderDark : AppColors.border,
                      width: NeoBrutalismTheme.borderWidth,
                    ),
                  ),
                  child: const Icon(
                    Icons.local_cafe,
                    color: AppColors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.cafe.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      if (widget.cafe.address.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          widget.cafe.address,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.outline,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.xs),
                      Wrap(
                        spacing: AppSpacing.xs,
                        runSpacing: AppSpacing.xxs,
                        children: [
                          CafeChip(
                            icon: Icons.location_on,
                            label: distanceLabel,
                          ),
                          if (widget.cafe.isWaitingForGame &&
                              widget.cafe.estimatedWaitMinutes != null)
                            CafeChip(
                              icon: Icons.hourglass_bottom,
                              label:
                                  'Chờ ~${widget.cafe.estimatedWaitMinutes}p',
                              color: AppColors.warning.withValues(alpha: 0.15),
                              textColor: AppColors.warningDark,
                            ),
                          if (widget.cafe.totalTableCount > 0)
                            CafeChip(
                              icon: Icons.table_restaurant,
                              label:
                                  '${widget.cafe.availableTableCount}/${widget.cafe.totalTableCount} bàn',
                            ),
                          if (widget.cafe.rating > 0)
                            CafeChip(
                              icon: Icons.star,
                              label: widget.cafe.rating.toStringAsFixed(1),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.chevron_right,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
