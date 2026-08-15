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
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      children: [
        const SizedBox(height: AppSpacing.md),
        const _StatsStackSkeleton(),
        const SizedBox(height: AppSpacing.md),
        const _InfoCardSkeleton(),
        const SizedBox(height: AppSpacing.md),
        const _InfoCardSkeleton(),
        const SizedBox(height: AppSpacing.md),
        const _QuickActionsSkeleton(),
        const SizedBox(height: AppSpacing.xxl),
      ],
    );
  }
}

class _StatsStackSkeleton extends StatelessWidget {
  const _StatsStackSkeleton();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.borderDark : AppColors.border;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        children: [
          for (var i = 0; i < 3; i++) ...[
            _StatCardSkeleton(borderColor: borderColor),
            if (i < 2) const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}

class _StatCardSkeleton extends StatelessWidget {
  const _StatCardSkeleton({required this.borderColor});

  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
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
            width: 36,
            height: 36,
            borderRadius: const BorderRadius.all(Radius.circular(10)),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                AppShimmer.box(
                  context: context,
                  width: 80,
                  height: 10,
                  borderRadius: 4,
                ),
                const SizedBox(height: AppSpacing.xs),
                AppShimmer.box(
                  context: context,
                  width: 60,
                  height: 18,
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
  const _InfoCardSkeleton();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.borderDark : AppColors.border;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Container(
        padding: AppSpacing.paddingAllMd,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: NeoBrutalismTheme.borderWidth),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppShimmer.box(context: context, width: 140, height: 18, borderRadius: 6),
            const SizedBox(height: AppSpacing.md),
            AppShimmer.textLines(
              context: context,
              lines: 4,
              lineHeight: 14,
              lastLineWidth: 200,
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionsSkeleton extends StatelessWidget {
  const _QuickActionsSkeleton();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.borderDark : AppColors.border;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Container(
        padding: AppSpacing.paddingAllSm,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: NeoBrutalismTheme.borderWidth),
        ),
        child: Row(
          children: [
            for (var i = 0; i < 4; i++) ...[
              if (i == 2) const SizedBox(width: AppSpacing.sm),
              if (i > 0 && i != 2) const SizedBox(width: AppSpacing.sm),
              const Expanded(
                child: _QuickActionTileSkeleton(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _QuickActionTileSkeleton extends StatelessWidget {
  const _QuickActionTileSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          AppShimmer.boxRadius(
            context: context,
            width: 32,
            height: 32,
            borderRadius: const BorderRadius.all(Radius.circular(8)),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: AppShimmer.box(
              context: context,
              height: 12,
              borderRadius: 4,
            ),
          ),
        ],
      ),
    );
  }
}
