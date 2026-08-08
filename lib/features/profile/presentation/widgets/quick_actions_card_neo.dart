import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:boardverse_mobile/core/theme/app_spacing.dart';
import 'package:boardverse_mobile/core/theme/app_colors.dart';
import 'package:boardverse_mobile/core/theme/neo_brutalism_theme.dart';

/// Single entry in the [QuickActionsGridNeo].
class QuickActionItemNeo {
  const QuickActionItemNeo({
    required this.icon,
    required this.title,
    required this.onTap,
    this.accentColor,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color? accentColor;
}

/// Neo-brutalism Quick Actions Grid - BIG CARDS, NO WRAPPER
/// 
/// Features:
/// - 4 cards BIG trong 2x2 grid
/// - KHÔNG có khung bao ngoài
/// - Icon to, title rõ ràng
/// - Press animation với scale
class QuickActionsGridNeo extends StatelessWidget {
  const QuickActionsGridNeo({super.key, required this.actions});

  final List<QuickActionItemNeo> actions;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.3,
      mainAxisSpacing: AppSpacing.md,
      crossAxisSpacing: AppSpacing.md,
      children: [
        for (final item in actions)
          _ActionTileNeo(
            item: item,
            accentColor: item.accentColor ?? AppColors.primary,
          ),
      ],
    );
  }
}

class _ActionTileNeo extends StatefulWidget {
  const _ActionTileNeo({
    required this.item,
    required this.accentColor,
  });

  final QuickActionItemNeo item;
  final Color accentColor;

  @override
  State<_ActionTileNeo> createState() => _ActionTileNeoState();
}

class _ActionTileNeoState extends State<_ActionTileNeo>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressCtrl;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.94).animate(
      CurvedAnimation(parent: _pressCtrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _pressCtrl.forward();
    HapticFeedback.mediumImpact();
  }

  void _onTapUp(TapUpDetails details) => _pressCtrl.reverse();
  void _onTapCancel() => _pressCtrl.reverse();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
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
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        onTap: widget.item.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          decoration: NeoBrutalismTheme.autoBox(
            context,
            backgroundColor: isPressed
                ? widget.accentColor.withValues(alpha: 0.15)
                : (isDark ? AppColors.surfaceDark : AppColors.surface),
            shadowColor: widget.accentColor.withValues(alpha: 0.2),
            borderRadius: 16,
          ),
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon lớn với neo-brutalist background
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm + 2),
                decoration: BoxDecoration(
                  color: widget.accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark ? AppColors.borderDark : AppColors.border,
                    width: NeoBrutalismTheme.borderWidth,
                  ),
                ),
                child: Icon(
                  widget.item.icon,
                  color: widget.accentColor,
                  size: 28,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              // Title
              Text(
                widget.item.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: isPressed
                      ? widget.accentColor
                      : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimary),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
