import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/neo_brutalism_theme.dart';

/// Neo-brutalism Card-style selectable option — bold borders + hard shadow when selected.
class FilterSelectableCard extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const FilterSelectableCard({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  State<FilterSelectableCard> createState() => _FilterSelectableCardState();
}

class _FilterSelectableCardState extends State<FilterSelectableCard>
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
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
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

    final bgColor = widget.selected
        ? AppColors.primary.withValues(alpha: 0.12)
        : (isDark ? AppColors.surfaceDark : AppColors.surface);
    final borderColor = widget.selected
        ? AppColors.primary
        : (isDark ? AppColors.borderDark : AppColors.border);
    final iconBgColor = widget.selected
        ? AppColors.primary
        : (isDark ? AppColors.surfaceElevatedDark : AppColors.surfaceVariant);
    final iconColor = widget.selected
        ? AppColors.white
        : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimary);
    final textColor = widget.selected
        ? AppColors.primary
        : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimary);

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
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: borderColor,
              width: widget.selected
                  ? NeoBrutalismTheme.borderWidthBold
                  : NeoBrutalismTheme.borderWidth,
            ),
            boxShadow: widget.selected
                ? NeoBrutalismTheme.lightShadow(
                    shadowColor: AppColors.primary.withValues(alpha: 0.3),
                  )
                : null,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.xs),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: borderColor,
                    width: NeoBrutalismTheme.borderWidth,
                  ),
                ),
                child: Icon(
                  widget.icon,
                  size: AppSpacing.md,
                  color: iconColor,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  widget.label,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: textColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (widget.selected)
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    size: 12,
                    color: AppColors.white,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
