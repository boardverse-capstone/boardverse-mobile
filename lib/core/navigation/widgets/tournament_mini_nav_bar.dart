import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/neo_brutalism_theme.dart';

/// Mini navigation bar for TournamentShell.
///
/// Provides quick tab switching while browsing tournaments.
class TournamentMiniNavBar extends StatelessWidget {
  const TournamentMiniNavBar({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
  });

  final int currentIndex;
  final ValueChanged<int> onTabSelected;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final bottomPadding = mediaQuery.padding.bottom;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: isDark
          ? NeoBrutalismTheme.brutalBoxDark(
              backgroundColor: AppColors.surfaceDark,
              borderColor: AppColors.borderDark,
              bold: true,
              borderRadius: 20,
            )
          : NeoBrutalismTheme.brutalBox(
              backgroundColor: AppColors.surface,
              borderColor: AppColors.border,
              bold: true,
              borderRadius: 20,
              shadowColor: AppColors.primary.withValues(alpha: 0.2),
            ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Container(
          height: 64 + bottomPadding,
          padding: EdgeInsets.only(bottom: bottomPadding),
          child: Row(
            children: [
              _MiniNavItem(
                icon: Icons.notifications_rounded,
                label: 'Hoạt động',
                isSelected: currentIndex == 0,
                onTap: () => onTabSelected(0),
              ),
              _MiniNavItem(
                icon: Icons.calendar_month_rounded,
                label: 'Đặt bàn',
                isSelected: currentIndex == 1,
                onTap: () => onTabSelected(1),
              ),
              _MiniNavItem(
                icon: Icons.explore_rounded,
                label: 'Khám phá',
                isSelected: currentIndex == 2,
                onTap: () => onTabSelected(2),
              ),
              _MiniNavItem(
                icon: Icons.groups_rounded,
                label: 'Phòng',
                isSelected: currentIndex == 3,
                onTap: () => onTabSelected(3),
              ),
              _MiniNavItem(
                icon: Icons.person_rounded,
                label: 'Cá nhân',
                isSelected: currentIndex == 4,
                onTap: () => onTabSelected(4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniNavItem extends StatefulWidget {
  const _MiniNavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<_MiniNavItem> createState() => _MiniNavItemState();
}

class _MiniNavItemState extends State<_MiniNavItem>
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
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
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
  }

  void _onTapUp(TapUpDetails details) => _pressCtrl.reverse();
  void _onTapCancel() => _pressCtrl.reverse();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final selectedColor = AppColors.primary;
    final unselectedColor = isDark ? Colors.grey[500] : Colors.grey[600];

    return Expanded(
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        onTap: () {
          HapticFeedback.selectionClick();
          widget.onTap();
        },
        behavior: HitTestBehavior.opaque,
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: child,
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(6),
                  decoration: widget.isSelected
                      ? BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(10),
                        )
                      : null,
                  child: Icon(
                    widget.icon,
                    size: 22,
                    color: widget.isSelected
                        ? Colors.white
                        : unselectedColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight:
                        widget.isSelected ? FontWeight.w800 : FontWeight.w500,
                    color: widget.isSelected
                        ? selectedColor
                        : unselectedColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
