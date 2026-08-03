import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';

/// Quick filter chip pill-style với:
/// - Scale animation khi tap
/// - Gradient background khi selected
/// - Check icon slide in/out khi selected
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
      duration: const Duration(milliseconds: 100),
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
          final scale = 1 - (_pressCtrl.value * 0.08);
          return Transform.scale(scale: scale, child: child);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs + 2,
          ),
          decoration: BoxDecoration(
            color: widget.selected ? null : theme.colorScheme.surfaceContainerHighest,
            gradient: widget.selected
                ? const LinearGradient(
                    colors: [AppColors.primary, AppColors.accent],
                  )
                : null,
            borderRadius: AppRadius.radiusFullAll,
            border: Border.all(
              color: widget.selected
                  ? Colors.transparent
                  : theme.colorScheme.outlineVariant,
              width: 1,
            ),
            boxShadow: widget.selected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      transitionBuilder: (child, animation) {
                        return ScaleTransition(
                          scale: animation,
                          child: FadeTransition(
                            opacity: animation,
                            child: child,
                          ),
                        );
                      },
                      child: widget.selected
                          ? const Icon(
                              Icons.check,
                              key: ValueKey('check'),
                              size: AppSpacing.md,
                              color: Colors.white,
                            )
                          : widget.icon != null
                              ? Icon(
                                  widget.icon,
                                  key: ValueKey('icon'),
                                  size: AppSpacing.md,
                                  color: theme.colorScheme.onSurface,
                                )
                              : const SizedBox.shrink(key: ValueKey('none')),
                    ),
                    if (widget.selected ||
                        widget.icon != null)
                      const SizedBox(width: AppSpacing.xxs),
                  ],
                ),
              ),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: (theme.textTheme.labelLarge ?? const TextStyle()).copyWith(
                  color: widget.selected
                      ? Colors.white
                      : theme.colorScheme.onSurface,
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

/// Horizontal list các QuickFilterChip — dùng cho quick filter dưới search
/// bar. Hỗ trợ auto-wrap khi tràn.
class QuickFilterChipBar extends StatelessWidget {
  final List<QuickFilterItem> items;

  const QuickFilterChipBar({
    super.key,
    required this.items,
  });

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
            if (i < items.length - 1)
              const SizedBox(width: AppSpacing.xs),
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