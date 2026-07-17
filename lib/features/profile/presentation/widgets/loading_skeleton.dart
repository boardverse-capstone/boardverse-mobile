import 'package:flutter/material.dart';

import 'package:boardverse_mobile/core/theme/app_radius.dart';
import 'package:boardverse_mobile/core/theme/app_shimmer.dart';
import 'package:boardverse_mobile/core/theme/app_spacing.dart';

/// Skeleton shimmer cho toàn bộ màn hình profile dashboard.
///
/// Bám sát cấu trúc của [AvatarHeader] + 2 [ProfileStatCard] + [PersonalInfoCard]
/// + [LocationCard] + khối action — để trải nghiệm loading mượt mà.
class ProfileLoadingSkeleton extends StatelessWidget {
  const ProfileLoadingSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      children: const [
        _HeaderSkeleton(),
        SizedBox(height: AppSpacing.lg),
        _StatsRowSkeleton(),
        SizedBox(height: AppSpacing.md),
        _InfoCardSkeleton(),
        SizedBox(height: AppSpacing.md),
        _InfoCardSkeleton(),
        SizedBox(height: AppSpacing.xxl),
      ],
    );
  }
}

class _HeaderSkeleton extends StatelessWidget {
  const _HeaderSkeleton();

  @override
  Widget build(BuildContext context) {
    return AppShimmer.container(
      context: context,
      borderRadius: const BorderRadius.vertical(
        bottom: Radius.circular(AppRadius.radiusHuge),
      ),
      child: Container(
        height: 280,
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE65100), Color(0xFFFF9E40), Color(0xFF00897B)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.xxl,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            AppShimmer.circle(context: context, size: 96),
            const SizedBox(height: AppSpacing.md),
            AppShimmer.box(context: context, width: 180, height: 22),
            const SizedBox(height: AppSpacing.xs),
            AppShimmer.box(context: context, width: 120, height: 14),
            const SizedBox(height: AppSpacing.sm),
            AppShimmer.box(context: context, width: 100, height: 24, borderRadius: 16),
            const SizedBox(height: AppSpacing.sm),
            AppShimmer.box(context: context, width: 220, height: 12),
            const SizedBox(height: AppSpacing.xxs),
            AppShimmer.box(context: context, width: 160, height: 12),
          ],
        ),
      ),
    );
  }
}

class _StatsRowSkeleton extends StatelessWidget {
  const _StatsRowSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        children: [
          Expanded(child: _StatCardSkeleton()),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: _StatCardSkeleton()),
        ],
      ),
    );
  }
}

class _StatCardSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.radiusMd),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppShimmer.box(context: context, width: 60, height: 10),
              AppShimmer.box(context: context, width: 24, height: 24, borderRadius: 8),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          AppShimmer.box(context: context, width: 80, height: 28),
        ],
      ),
    );
  }
}

class _InfoCardSkeleton extends StatelessWidget {
  const _InfoCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.radiusMd),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.6),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppShimmer.box(context: context, width: 140, height: 18),
            const SizedBox(height: AppSpacing.md),
            AppShimmer.textLines(context: context, lines: 4, lineHeight: 14),
          ],
        ),
      ),
    );
  }
}
