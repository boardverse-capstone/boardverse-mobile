import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

/// Neo-brutalism Section header — bold title + animated gradient underline.
class AnimatedSectionHeader extends StatefulWidget {
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const AnimatedSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  State<AnimatedSectionHeader> createState() => _AnimatedSectionHeaderState();
}

class _AnimatedSectionHeaderState extends State<AnimatedSectionHeader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: AppSpacing.paddingHorizontalMd,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title.toUpperCase(),
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                    if (widget.subtitle != null) ...[
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        widget.subtitle!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (widget.actionLabel != null && widget.onAction != null)
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDark ? AppColors.borderDark : AppColors.border,
                      width: 2,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.black,
                        blurRadius: 0,
                        offset: Offset(2, 2),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: widget.onAction,
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xs,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.actionLabel!,
                              style: const TextStyle(
                                color: AppColors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.arrow_forward,
                              size: 14,
                              color: AppColors.white,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          // Underline gradient animation
          AnimatedBuilder(
            animation: _ctrl,
            builder: (context, _) {
              return ClipRRect(
                borderRadius: const BorderRadius.all(Radius.circular(8)),
                child: SizedBox(
                  height: 4,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final width =
                          constraints.maxWidth * _ctrl.value.clamp(0.0, 1.0);
                      return Stack(
                        children: [
                          Container(
                            width: constraints.maxWidth,
                            color: isDark
                                ? AppColors.borderDark
                                : AppColors.border,
                          ),
                          Container(
                            width: width,
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.primary,
                                  AppColors.accent,
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
