import 'package:flutter/material.dart';

import 'package:boardverse_mobile/core/theme/app_radius.dart';
import 'package:boardverse_mobile/core/theme/app_shimmer.dart';
import 'package:boardverse_mobile/core/theme/app_spacing.dart';

/// Skeleton shimmer cho toàn bộ màn hình profile dashboard.
///
/// Bám sát cấu trúc mới:
/// - 3 [ProfileStatCard] (ELO / Level / Karma) stacked dọc trên mobile.
/// - 1 [PersonalInfoCard] + 1 [LocationCard] + 1 [QuickActionsCard] grid 2x2.
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        children: [
          const _StatCardSkeleton(),
          const SizedBox(height: AppSpacing.sm),
          const _StatCardSkeleton(),
          const SizedBox(height: AppSpacing.sm),
          const _StatCardSkeleton(),
        ],
      ),
    );
  }
}

class _StatCardSkeleton extends StatelessWidget {
  const _StatCardSkeleton();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: AppRadius.radiusLgAll,
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          AppShimmer.boxRadius(
            context: context,
            width: 36,
            height: 36,
            borderRadius: AppRadius.radiusSmAll,
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
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Container(
        padding: AppSpacing.paddingAllMd,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: AppRadius.radiusLgAll,
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppShimmer.box(context: context, width: 140, height: 18),
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
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Container(
        padding: AppSpacing.paddingAllSm,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: AppRadius.radiusLgAll,
          border: Border.all(color: theme.colorScheme.outlineVariant),
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
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: AppRadius.radiusMdAll,
      ),
      child: Row(
        children: [
          AppShimmer.boxRadius(
            context: context,
            width: 32,
            height: 32,
            borderRadius: AppRadius.radiusSmAll,
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
