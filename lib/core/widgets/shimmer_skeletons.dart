import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';

/// Shimmer primitives for loading placeholders.
class ShimmerBase extends StatelessWidget {
  final double width;
  final double height;
  final EdgeInsetsGeometry? margin;
  final double radius;

  const ShimmerBase({
    super.key,
    required this.width,
    required this.height,
    this.margin,
    this.radius = 8,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? AppColors.surfaceDark : AppColors.white;
    final highlight =
        isDark ? AppColors.surfaceDark : AppColors.surfaceVariant;

    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: base,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Shimmer.fromColors(
        baseColor: base,
        highlightColor: highlight,
        period: const Duration(milliseconds: 1400),
        child: Container(
          decoration: BoxDecoration(
            color: base,
            borderRadius: BorderRadius.circular(radius),
          ),
        ),
      ),
    );
  }
}

/// Card-style skeleton matching tournament list items.
class TournamentCardSkeleton extends StatelessWidget {
  const TournamentCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: AppRadius.radiusMdAll,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: ShimmerBase(
                  width: double.infinity,
                  height: 18,
                  radius: 8,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              ShimmerBase(
                width: 64,
                height: 18,
                radius: 8,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          ShimmerBase(
            width: 220,
            height: 12,
            radius: 4,
          ),
          const SizedBox(height: AppSpacing.sm),
          const Row(
            children: [
              ShimmerBase(width: 120, height: 12, radius: 4),
              Spacer(),
              ShimmerBase(width: 48, height: 12, radius: 4),
            ],
          ),
        ],
      ),
    );
  }
}

/// A list of card skeletons for "list pages".
class TournamentListSkeleton extends StatelessWidget {
  final int itemCount;
  const TournamentListSkeleton({super.key, this.itemCount = 4});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.xl,
      ),
      itemCount: itemCount,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (_, _) => const TournamentCardSkeleton(),
    );
  }
}

/// Row-style skeleton matching [LeaderboardPage] tiles.
class LeaderboardTileSkeleton extends StatelessWidget {
  const LeaderboardTileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: AppRadius.radiusMdAll,
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: const Row(
        children: [
          ShimmerBase(width: 44, height: 44, radius: 22),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerBase(width: 160, height: 14, radius: 4),
                SizedBox(height: 6),
                ShimmerBase(width: 100, height: 12, radius: 4),
              ],
            ),
          ),
          SizedBox(width: AppSpacing.sm),
          ShimmerBase(width: 48, height: 22, radius: 8),
        ],
      ),
    );
  }
}

class LeaderboardListSkeleton extends StatelessWidget {
  final int itemCount;
  const LeaderboardListSkeleton({super.key, this.itemCount = 6});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.xl,
      ),
      itemCount: itemCount,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.xs),
      itemBuilder: (_, _) => const LeaderboardTileSkeleton(),
    );
  }
}

/// Skeleton for [EloHistoryPage]'s hero section + chart + list.
class EloHistorySkeleton extends StatelessWidget {
  const EloHistorySkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.xl,
      ),
      children: [
        ShimmerBase(
          width: double.infinity,
          height: 96,
          radius: AppRadius.radiusMd,
        ),
        const SizedBox(height: AppSpacing.md),
        const ShimmerBase(width: 120, height: 16, radius: 4),
        const SizedBox(height: AppSpacing.sm),
        ShimmerBase(
          width: double.infinity,
          height: 180,
          radius: AppRadius.radiusMd,
        ),
        const SizedBox(height: AppSpacing.xl),
        const ShimmerBase(width: 140, height: 16, radius: 4),
        const SizedBox(height: AppSpacing.sm),
        const _EloHistoryItemSkeleton(),
        const SizedBox(height: AppSpacing.xs),
        const _EloHistoryItemSkeleton(),
        const SizedBox(height: AppSpacing.xs),
        const _EloHistoryItemSkeleton(),
      ],
    );
  }
}

class _EloHistoryItemSkeleton extends StatelessWidget {
  const _EloHistoryItemSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: AppRadius.radiusMdAll,
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: const Row(
        children: [
          ShimmerBase(width: 48, height: 48, radius: 8),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerBase(width: 200, height: 14, radius: 4),
                SizedBox(height: 6),
                ShimmerBase(width: 160, height: 12, radius: 4),
              ],
            ),
          ),
        ],
      ),
    );
  }
}