import 'package:flutter/material.dart';

import 'package:boardverse/core/theme/app_colors.dart';
import 'package:boardverse/core/theme/app_shimmer.dart';
import 'package:boardverse/core/theme/app_spacing.dart';
import 'package:boardverse/core/theme/neo_brutalism_theme.dart';

/// Neo-brutalism Skeleton shimmer cho toàn bộ màn hình profile.
class ProfileLoadingSkeleton extends StatelessWidget {
  const ProfileLoadingSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 380;

    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      children: [
        SizedBox(height: isSmallScreen ? AppSpacing.sm : AppSpacing.md),
        _StatsStackSkeleton(isSmallScreen: isSmallScreen),
        SizedBox(height: isSmallScreen ? AppSpacing.sm : AppSpacing.md),
        _InfoCardSkeleton(isSmallScreen: isSmallScreen),
        SizedBox(height: isSmallScreen ? AppSpacing.sm : AppSpacing.md),
        _InfoCardSkeleton(isSmallScreen: isSmallScreen),
        SizedBox(height: isSmallScreen ? AppSpacing.sm : AppSpacing.md),
        _QuickActionsSkeleton(isSmallScreen: isSmallScreen),
        SizedBox(height: isSmallScreen ? AppSpacing.lg : AppSpacing.xxl),
      ],
    );
  }
}

class _StatsStackSkeleton extends StatelessWidget {
  const _StatsStackSkeleton({this.isSmallScreen = false});

  final bool isSmallScreen;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.borderDark : AppColors.border;
    final horizontalPadding = isSmallScreen ? AppSpacing.md : AppSpacing.lg;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Column(
        children: [
          for (var i = 0; i < 3; i++) ...[
            _StatCardSkeleton(borderColor: borderColor, isSmallScreen: isSmallScreen),
            if (i < 2) SizedBox(height: isSmallScreen ? AppSpacing.xs : AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}

class _StatCardSkeleton extends StatelessWidget {
  const _StatCardSkeleton({required this.borderColor, this.isSmallScreen = false});

  final Color borderColor;
  final bool isSmallScreen;

  @override
  Widget build(BuildContext context) {
    final iconSize = isSmallScreen ? 28.0 : 36.0;
    final titleWidth = isSmallScreen ? 60.0 : 80.0;
    final valueWidth = isSmallScreen ? 45.0 : 60.0;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? AppSpacing.sm : AppSpacing.md,
        vertical: isSmallScreen ? AppSpacing.xs : AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: NeoBrutalismTheme.borderWidth),
      ),
      child: Row(
        children: [
          AppShimmer.boxRadius(
            context: context,
            width: iconSize,
            height: iconSize,
            borderRadius: const BorderRadius.all(Radius.circular(10)),
          ),
          SizedBox(width: isSmallScreen ? AppSpacing.xs : AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                AppShimmer.box(
                  context: context,
                  width: titleWidth,
                  height: isSmallScreen ? 8.0 : 10.0,
                  borderRadius: 4,
                ),
                SizedBox(height: isSmallScreen ? 2 : AppSpacing.xs),
                AppShimmer.box(
                  context: context,
                  width: valueWidth,
                  height: isSmallScreen ? 14.0 : 18.0,
                  borderRadius: 4,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCardSkeleton extends StatelessWidget {
  const _InfoCardSkeleton({this.isSmallScreen = false});

  final bool isSmallScreen;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.borderDark : AppColors.border;
    final horizontalPadding = isSmallScreen ? AppSpacing.md : AppSpacing.lg;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Container(
        padding: EdgeInsets.all(isSmallScreen ? AppSpacing.sm : AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: NeoBrutalismTheme.borderWidth),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppShimmer.box(
              context: context,
              width: isSmallScreen ? 100 : 140,
              height: isSmallScreen ? 14.0 : 18.0,
              borderRadius: 6,
            ),
            SizedBox(height: isSmallScreen ? AppSpacing.sm : AppSpacing.md),
            AppShimmer.textLines(
              context: context,
              lines: isSmallScreen ? 3 : 4,
              lineHeight: isSmallScreen ? 12.0 : 14.0,
              lastLineWidth: isSmallScreen ? 150 : 200,
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionsSkeleton extends StatelessWidget {
  const _QuickActionsSkeleton({this.isSmallScreen = false});

  final bool isSmallScreen;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.borderDark : AppColors.border;
    final horizontalPadding = isSmallScreen ? AppSpacing.md : AppSpacing.lg;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Container(
        padding: EdgeInsets.all(isSmallScreen ? AppSpacing.xs : AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: NeoBrutalismTheme.borderWidth),
        ),
        child: Column(
          children: [
            for (var i = 0; i < 2; i++) ...[
              if (i > 0) SizedBox(height: isSmallScreen ? AppSpacing.xs : AppSpacing.sm),
              Row(
                children: [
                  for (var j = 0; j < 2; j++) ...[
                    if (j > 0) SizedBox(width: isSmallScreen ? AppSpacing.xs : AppSpacing.sm),
                    Expanded(
                      child: _QuickActionTileSkeleton(isSmallScreen: isSmallScreen),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _QuickActionTileSkeleton extends StatelessWidget {
  const _QuickActionTileSkeleton({this.isSmallScreen = false});

  final bool isSmallScreen;

  @override
  Widget build(BuildContext context) {
    final iconSize = isSmallScreen ? 24.0 : 32.0;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? AppSpacing.xs : AppSpacing.sm,
        vertical: isSmallScreen ? AppSpacing.xs : AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          AppShimmer.boxRadius(
            context: context,
            width: iconSize,
            height: iconSize,
            borderRadius: const BorderRadius.all(Radius.circular(8)),
          ),
          SizedBox(width: isSmallScreen ? AppSpacing.xs : AppSpacing.sm),
          Expanded(
            child: AppShimmer.box(
              context: context,
              height: isSmallScreen ? 10.0 : 12.0,
              borderRadius: 4,
            ),
          ),
        ],
      ),
    );
  }
}
