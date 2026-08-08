import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/neo_brutalism_theme.dart';

/// Neo-brutalism Duration row — bold border + hard shadow when selected.
class FilterDurationRow extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const FilterDurationRow({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  State<FilterDurationRow> createState() => _FilterDurationRowState();
}

class _FilterDurationRowState extends State<FilterDurationRow>
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isPressed = _pressCtrl.isAnimating && _pressCtrl.value > 0.5;

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
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: widget.selected
                ? AppColors.primary.withValues(alpha: 0.12)
                : (isDark ? AppColors.surfaceDark : AppColors.surface),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.selected
                  ? AppColors.primary
                  : (isDark ? AppColors.borderDark : AppColors.border),
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
                padding: const EdgeInsets.all(AppSpacing.xs + 1),
                decoration: BoxDecoration(
                  color: widget.selected
                      ? AppColors.primary
                      : (isDark
                          ? AppColors.surfaceElevatedDark
                          : AppColors.surfaceVariant),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: widget.selected
                        ? AppColors.primary
                        : (isDark ? AppColors.borderDark : AppColors.border),
                    width: 2,
                  ),
                ),
                child: Icon(
                  widget.icon,
                  size: AppSpacing.md + 2,
                  color: widget.selected
                      ? AppColors.white
                      : AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  widget.label,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: widget.selected
                        ? AppColors.primary
                        : (isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimary),
                  ),
                ),
              ),
              AnimatedScale(
                scale: widget.selected ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutBack,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: AppColors.white,
                    size: 14,
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
