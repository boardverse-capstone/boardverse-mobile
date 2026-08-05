import 'package:flutter/material.dart';

import 'package:boardverse_mobile/core/theme/app_icons.dart';
import 'package:boardverse_mobile/core/theme/app_radius.dart';
import 'package:boardverse_mobile/core/theme/app_spacing.dart';

/// Single entry in the [QuickActionsCard] grid.
class QuickActionItem {
  const QuickActionItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.tint,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  /// Optional tint color for the icon. Nếu không truyền sẽ dùng `primary`.
  final Color? tint;
}

/// Grid 2x2 hiển thị các thao tác nhanh (bạn bè, xếp hạng, lịch sử, cài đặt).
///
/// Mỗi item là 1 ô vuông bo tròn, icon trên + label dưới — phong cách minimal.
/// Toàn bộ grid được bọc trong 1 surface bo góc với border + shadow nhẹ.
/// Có gradient hover state và press animation.
class QuickActionsCard extends StatelessWidget {
  const QuickActionsCard({super.key, required this.actions});

  final List<QuickActionItem> actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: AppRadius.radiusLgAll,
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 1.6,
        mainAxisSpacing: AppSpacing.sm,
        crossAxisSpacing: AppSpacing.sm,
        children: [
          for (final item in actions) _ActionTile(item: item),
        ],
      ),
    );
  }
}

class _ActionTile extends StatefulWidget {
  const _ActionTile({required this.item});

  final QuickActionItem item;

  @override
  State<_ActionTile> createState() => _ActionTileState();
}

class _ActionTileState extends State<_ActionTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressCtrl;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      duration: const Duration(milliseconds: 140),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _pressCtrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _pressCtrl.forward();
  }

  void _onTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _pressCtrl.reverse();
  }

  void _onTapCancel() {
    setState(() => _isPressed = false);
    _pressCtrl.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tint = widget.item.tint ?? theme.colorScheme.primary;

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        );
      },
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        onTap: widget.item.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            gradient: _isPressed
                ? LinearGradient(
                    colors: [
                      tint.withValues(alpha: 0.15),
                      tint.withValues(alpha: 0.08),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: _isPressed ? null : theme.colorScheme.surfaceContainerHighest,
            borderRadius: AppRadius.radiusMdAll,
            border: Border.all(
              color: _isPressed
                  ? tint.withValues(alpha: 0.3)
                  : Colors.transparent,
            ),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.xs),
                decoration: BoxDecoration(
                  color: _isPressed
                      ? tint.withValues(alpha: 0.2)
                      : tint.withValues(alpha: 0.12),
                  borderRadius: AppRadius.radiusSmAll,
                ),
                child: Icon(
                  widget.item.icon,
                  color: tint,
                  size: AppIcons.md,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  widget.item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              Icon(
                AppIcons.forward,
                size: AppIcons.sm,
                color: _isPressed
                    ? tint
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
