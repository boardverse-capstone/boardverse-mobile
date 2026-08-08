import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/neo_brutalism_theme.dart';

/// Neo-brutalism Sticky bottom bar — badge + Áp dụng button.
class FilterBottomBar extends StatefulWidget {
  final int totalSelected;
  final VoidCallback onApply;

  const FilterBottomBar({
    super.key,
    required this.totalSelected,
    required this.onApply,
  });

  @override
  State<FilterBottomBar> createState() => _FilterBottomBarState();
}

class _FilterBottomBarState extends State<FilterBottomBar>
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

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surface,
          border: Border(
            top: BorderSide(
              color: isDark ? AppColors.borderDark : AppColors.border,
              width: NeoBrutalismTheme.borderWidth,
            ),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(AppSpacing.huge),
                border: Border.all(
                  color: isDark ? AppColors.borderDark : AppColors.border,
                  width: NeoBrutalismTheme.borderWidth,
                ),
                boxShadow: NeoBrutalismTheme.lightShadow(
                  shadowColor: AppColors.primary.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.filter_alt,
                    size: AppSpacing.sm + 2,
                    color: AppColors.white,
                  ),
                  const SizedBox(width: AppSpacing.xxs),
                  Text(
                    '${widget.totalSelected}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      color: AppColors.white,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: AnimatedBuilder(
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
                    HapticFeedback.mediumImpact();
                  },
                  onTapUp: (_) => _pressCtrl.reverse(),
                  onTapCancel: () => _pressCtrl.reverse(),
                  onTap: widget.onApply,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.md,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark
                            ? AppColors.borderDark
                            : AppColors.border,
                        width: NeoBrutalismTheme.borderWidth,
                      ),
                      boxShadow: NeoBrutalismTheme.lightShadow(
                        shadowColor: AppColors.primary.withValues(alpha: 0.5),
                      ),
                    ),
                    child: const Text(
                      'ÁP DỤNG',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        letterSpacing: 1.2,
                      ),
                    ),
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
