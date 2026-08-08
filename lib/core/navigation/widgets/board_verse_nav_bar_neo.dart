import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/neo_brutalism_theme.dart';
import '../nav_tab.dart';
import '../navigation_cubit.dart';

/// Neo-brutalism Bottom Navigation Bar
/// 
/// Features:
/// - 5 tabs đều nhau
/// - Compact design tránh overflow
/// - Brand colors
class BoardVerseNavBarNeo extends StatelessWidget {
  final Function(int) onTabSelected;

  const BoardVerseNavBarNeo({
    super.key,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    return BlocSelector<NavigationCubit, NavigationState, int>(
      selector: (state) => state.currentIndex,
      builder: (context, currentIndex) => _NavBarContentNeo(
        currentIndex: currentIndex,
        onTabSelected: onTabSelected,
      ),
    );
  }
}

class _NavBarContentNeo extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTabSelected;

  const _NavBarContentNeo({
    required this.currentIndex,
    required this.onTabSelected,
  });

  void _onTabTapped(int index) {
    HapticFeedback.selectionClick();
    onTabSelected(index);
  }

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
              for (final tab in NavTab.values)
                Expanded(
                  child: _NavItemNeo(
                    icon: _iconFor(tab),
                    label: tab.label,
                    isSelected: currentIndex == tab.tabIndex,
                    onTap: () => _onTabTapped(tab.tabIndex),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconFor(NavTab tab) {
    switch (tab) {
      case NavTab.home:
        return Icons.home_rounded;
      case NavTab.bookings:
        return Icons.calendar_month_rounded;
      case NavTab.discovery:
        return Icons.explore_rounded;
      case NavTab.tournament:
        return Icons.emoji_events_rounded;
      case NavTab.profile:
        return Icons.person_rounded;
    }
  }
}

class _NavItemNeo extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItemNeo({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_NavItemNeo> createState() => _NavItemNeoState();
}

class _NavItemNeoState extends State<_NavItemNeo>
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

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.onTap,
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
              // Icon
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
              // Label - nhỏ hơn
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
    );
  }
}
