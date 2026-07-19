import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_radius.dart';
import '../nav_tab.dart';
import '../navigation_cubit.dart';

/// Modern Bottom Navigation Bar - BoardVerse Mobile
/// Features:
/// - Glassmorphism design with blur backdrop
/// - Large, readable labels
/// - Floating design with margin from bottom
/// - Smooth animations
/// - Active indicator with gradient
/// - Center FAB slot for the "Khám phá" discovery action
class BoardVerseNavBar extends StatelessWidget {
  final Function(int) onTabSelected;

  const BoardVerseNavBar({
    super.key,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    // BlocSelector rebuilds ONLY this widget when currentIndex changes,
    // leaving the Scaffold/PageView subtree untouched. This is what kills
    // the jank that was caused by rebuilding the entire widget tree on
    // every tab switch.
    return BlocSelector<NavigationCubit, NavigationState, int>(
      selector: (state) => state.currentIndex,
      builder: (context, currentIndex) => _NavBarContent(
        currentIndex: currentIndex,
        onTabSelected: onTabSelected,
      ),
    );
  }
}

class _NavBarContent extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTabSelected;

  const _NavBarContent({
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

    final centerIndex = NavTab.discovery.tabIndex;
    final centerButtonSize = 56.0;

    // Clamp defensively so a transient out-of-range value (e.g. during a
    // bounce-back swipe) never causes "no tab is selected".
    final safeIndex =
        currentIndex.clamp(0, NavTab.values.length - 1).toInt();

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: ClipRRect(
        borderRadius: AppRadius.radiusXlAll,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            height: 72 + bottomPadding,
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.surfaceDark.withValues(alpha: 0.85)
                  : AppColors.white.withValues(alpha: 0.9),
              borderRadius: AppRadius.radiusXlAll,
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.05),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.5)
                      : Colors.black.withValues(alpha: 0.15),
                  blurRadius: 24,
                  offset: const Offset(0, 6),
                ),
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.3)
                      : Colors.black.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.only(bottom: bottomPadding),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Row(
                    children: [
                      for (final tab in NavTab.values)
                        if (tab.tabIndex == centerIndex)
                          // Reserved slot for the centered FAB. Width matches
                          // the FAB so flanking items stay balanced even if
                          // the FAB size changes.
                          SizedBox(width: centerButtonSize)
                        else
                          _NavItemV2(
                            icon: _iconFor(tab),
                            label: tab.label,
                            isSelected: safeIndex == tab.tabIndex,
                            onTap: () => _onTabTapped(tab.tabIndex),
                          ),
                    ],
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: _CenterDiscoveryButton(
                        isSelected: safeIndex == centerIndex,
                        onTap: () => _onTabTapped(centerIndex),
                        size: centerButtonSize,
                      ),
                    ),
                  ),
                ],
              ),
            ),
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
        return Icons.groups_rounded;
      case NavTab.discovery:
        return Icons.explore_rounded;
      case NavTab.tournament:
        return Icons.emoji_events_rounded;
      case NavTab.profile:
        return Icons.person_rounded;
    }
  }
}

class _NavItemV2 extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItemV2({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.translucent,
        child: SizedBox(
          height: 64,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 52,
                height: 36,
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    Icon(
                      icon,
                      size: 26,
                      color: isSelected
                          ? AppColors.primary
                          : (isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected
                      ? AppColors.primary
                      : (isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CenterDiscoveryButton extends StatelessWidget {
  final bool isSelected;
  final VoidCallback onTap;
  final double size;

  const _CenterDiscoveryButton({
    required this.isSelected,
    required this.onTap,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isSelected
                ? [AppColors.primary, AppColors.secondary]
                : [AppColors.primaryLight, AppColors.primary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.4),
              blurRadius: isSelected ? 16 : 12,
              spreadRadius: isSelected ? 2 : 0,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: isDark ? AppColors.surfaceDark : AppColors.white,
            width: 3,
          ),
        ),
        child: const Icon(
          Icons.explore_rounded,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }
}

/// Smooth page transition wrapper
class AnimatedPageTransition extends StatelessWidget {
  final Widget child;
  final int currentIndex;

  const AnimatedPageTransition({
    super.key,
    required this.child,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.05, 0),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: KeyedSubtree(key: ValueKey(currentIndex), child: child),
    );
  }
}