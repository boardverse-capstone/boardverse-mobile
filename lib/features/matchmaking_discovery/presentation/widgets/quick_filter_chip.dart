import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/neo_brutalism_theme.dart';

/// Quick filter chip Neo-brutalism style với:
/// - Press scale animation
/// - Bold border khi selected
/// - Hard offset shadow khi selected
class QuickFilterChip extends StatefulWidget {
  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;

  const QuickFilterChip({
    super.key,
    required this.label,
    this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  State<QuickFilterChip> createState() => _QuickFilterChipState();
}

class _QuickFilterChipState extends State<QuickFilterChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressCtrl;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
    );
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _pressCtrl.forward();
    HapticFeedback.lightImpact();
  }

  void _onTapUp(TapUpDetails details) => _pressCtrl.reverse();
  void _onTapCancel() => _pressCtrl.reverse();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isPressed = _pressCtrl.isAnimating && _pressCtrl.value > 0.5;

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _pressCtrl,
        builder: (context, child) {
          return Transform.scale(
            scale: 1 - (_pressCtrl.value * 0.05),
            child: Transform.translate(
              offset: isPressed ? const Offset(2, 2) : Offset.zero,
              child: child,
            ),
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs + 2,
          ),
          decoration: BoxDecoration(
            color: widget.selected
                ? AppColors.primary
                : (isDark ? AppColors.surfaceDark : AppColors.surface),
            borderRadius: AppRadius.radiusFullAll,
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
                    shadowColor: AppColors.primary.withValues(alpha: 0.4),
                  )
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, animation) {
                  return ScaleTransition(
                    scale: animation,
                    child: FadeTransition(opacity: animation, child: child),
                  );
                },
                child: widget.selected
                    ? const Icon(
                        Icons.check,
                        key: ValueKey('check'),
                        size: AppSpacing.md,
                        color: AppColors.white,
                      )
                    : widget.icon != null
                        ? Icon(
                            widget.icon,
                            key: ValueKey('icon'),
                            size: AppSpacing.md,
                            color: isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimary,
                          )
                        : const SizedBox.shrink(key: ValueKey('none')),
              ),
              if (widget.selected || widget.icon != null)
                const SizedBox(width: AppSpacing.xxs),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: (theme.textTheme.labelLarge ?? const TextStyle()).copyWith(
                  color: widget.selected
                      ? AppColors.white
                      : (isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimary),
                  fontWeight: FontWeight.w700,
                ),
                child: Text(widget.label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Horizontal list các QuickFilterChip — dùng cho quick filter dưới search bar.
class QuickFilterChipBar extends StatelessWidget {
  final List<QuickFilterItem> items;

  const QuickFilterChipBar({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: AppSpacing.paddingHorizontalMd,
      child: Row(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            QuickFilterChip(
              label: items[i].label,
              icon: items[i].icon,
              selected: items[i].selected,
              onTap: items[i].onTap,
            ),
            if (i < items.length - 1) const SizedBox(width: AppSpacing.xs),
          ],
        ],
      ),
    );
  }
}

class QuickFilterItem {
  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;

  const QuickFilterItem({
    required this.label,
    this.icon,
    required this.selected,
    required this.onTap,
  });
}
