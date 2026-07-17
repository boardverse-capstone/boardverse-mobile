import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_radius.dart';

/// Modern Bottom Navigation Bar - BoardVerse Mobile
/// Features:
/// - Glassmorphism design with blur backdrop
/// - Large, readable labels
/// - Floating design with margin from bottom
/// - Smooth animations
/// - Active indicator with gradient
class BoardVerseNavBar extends StatefulWidget {
  final int currentIndex;
  final int lobbyCount;
  final bool hasBookingBadge;
  final bool isPlayingBadge;
  final int friendInviteCount;
  final Function(int) onTabSelected;

  const BoardVerseNavBar({
    super.key,
    required this.currentIndex,
    required this.lobbyCount,
    required this.hasBookingBadge,
    required this.isPlayingBadge,
    required this.friendInviteCount,
    required this.onTabSelected,
  });

  @override
  State<BoardVerseNavBar> createState() => _BoardVerseNavBarState();
}

class _BoardVerseNavBarState extends State<BoardVerseNavBar> {
  void _onTabTapped(int index) {
    HapticFeedback.selectionClick();
    widget.onTabSelected(index);
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final bottomPadding = mediaQuery.padding.bottom;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: ClipRRect(
        borderRadius: AppRadius.radiusXlAll,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
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
                  // Navigation items
                  Row(
                    children: [
                      _NavItemV2(
                        icon: Icons.home_rounded,
                        label: 'Trang chủ',
                        isSelected: widget.currentIndex == 0,
                        onTap: () => _onTabTapped(0),
                      ),
                      _NavItemV2(
                        icon: Icons.groups_rounded,
                        label: 'Phòng chờ',
                        isSelected: widget.currentIndex == 1,
                        badgeCount: widget.lobbyCount,
                        onTap: () => _onTabTapped(1),
                      ),
                      const SizedBox(width: 56),
                      _NavItemV2(
                        icon: Icons.emoji_events_rounded,
                        label: 'Giải đấu',
                        isSelected: widget.currentIndex == 3,
                        onTap: () => _onTabTapped(3),
                      ),
                      _NavItemV2(
                        icon: Icons.person_rounded,
                        label: 'Cá nhân',
                        isSelected: widget.currentIndex == 4,
                        badgeCount: widget.friendInviteCount,
                        onTap: () => _onTabTapped(4),
                      ),
                    ],
                  ),
                  // Center FAB - Khám phá
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: _CenterDiscoveryButton(
                        isSelected: widget.currentIndex == 2,
                        onTap: () => _onTabTapped(2),
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
}

class _NavItemV2 extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final int badgeCount;
  final VoidCallback onTap;

  const _NavItemV2({
    required this.icon,
    required this.label,
    required this.isSelected,
    this.badgeCount = 0,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasBadge = badgeCount > 0;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
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
                    if (hasBadge)
                      Positioned(
                        top: -2,
                        right: 4,
                        child: _BadgeWidget(count: badgeCount),
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

class _BadgeWidget extends StatelessWidget {
  final int count;

  const _BadgeWidget({
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    final hasAlert = count > 0;
    
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 300),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            constraints: const BoxConstraints(minWidth: 18),
            decoration: BoxDecoration(
              color: hasAlert ? AppColors.error : AppColors.primary,
              borderRadius: AppRadius.radiusXxsAll,
              boxShadow: [
                BoxShadow(
                  color: (hasAlert ? AppColors.error : AppColors.primary)
                      .withValues(alpha: 0.4),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              count > 99 ? '99+' : '$count',
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        );
      },
    );
  }
}

class _CenterDiscoveryButton extends StatelessWidget {
  final bool isSelected;
  final VoidCallback onTap;

  const _CenterDiscoveryButton({
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 56,
        height: 56,
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
