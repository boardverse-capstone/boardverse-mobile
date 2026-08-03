import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';

/// Danh sách skeleton cho trang danh sách game — dùng shimmer để thay thế
/// `CircularProgressIndicator` trơn, cho cảm giác app phản hồi nhanh hơn.
class GameSkeletonList extends StatelessWidget {
  final int itemCount;

  const GameSkeletonList({super.key, this.itemCount = 6});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      highlightColor: Theme.of(context).colorScheme.surface,
      child: ListView.builder(
        padding: AppSpacing.paddingAllMd,
        itemCount: itemCount,
        itemBuilder: (context, index) => const _GameSkeletonCard(),
      ),
    );
  }
}

class _GameSkeletonCard extends StatelessWidget {
  const _GameSkeletonCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: AppRadius.radiusMdAll,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 4 / 3,
            child: Container(color: theme.colorScheme.surfaceContainerHighest),
          ),
          Padding(
            padding: AppSpacing.paddingAllSm,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: AppSpacing.md,
                  width: double.infinity,
                  color: theme.colorScheme.surfaceContainerHighest,
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: AppSpacing.sm,
                        color: theme.colorScheme.surfaceContainerHighest,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Container(
                        height: AppSpacing.sm,
                        color: theme.colorScheme.surfaceContainerHighest,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Container(
                  height: AppSpacing.md,
                  width: AppSpacing.xxxl * 2,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: AppRadius.radiusFullAll,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Skeleton cho trang chi tiết game — header ảnh + vài dòng text giả lập.
class GameDetailSkeleton extends StatelessWidget {
  const GameDetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Shimmer.fromColors(
      baseColor: theme.colorScheme.surfaceContainerHighest,
      highlightColor: theme.colorScheme.surface,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            height: AppSpacing.huge * 3,
            color: theme.colorScheme.surfaceContainerHighest,
          ),
          Padding(
            padding: AppSpacing.paddingAllMd,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: AppSpacing.lg,
                  width: AppSpacing.xxxl * 3,
                  color: theme.colorScheme.surfaceContainerHighest,
                ),
                const SizedBox(height: AppSpacing.md),
                Container(
                  height: AppSpacing.md,
                  color: theme.colorScheme.surfaceContainerHighest,
                ),
                const SizedBox(height: AppSpacing.xs),
                Container(
                  height: AppSpacing.md,
                  color: theme.colorScheme.surfaceContainerHighest,
                ),
                const SizedBox(height: AppSpacing.xs),
                Container(
                  height: AppSpacing.md,
                  width: AppSpacing.xxxl * 4,
                  color: theme.colorScheme.surfaceContainerHighest,
                ),
                const SizedBox(height: AppSpacing.xl),
                Container(
                  height: AppSpacing.xxxl,
                  color: theme.colorScheme.surfaceContainerHighest,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}