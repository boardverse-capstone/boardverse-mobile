import 'package:flutter/material.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shimmer.dart';
import '../../../../core/theme/app_spacing.dart';

/// Skeleton card cho danh sách reservation khi đang load.
///
/// Tái sử dụng neo-brutalism layout của `ReservationCard` nhưng thay
/// thế icon / text bằng shimmer placeholder. Player thấy "loading" ngay
/// lập tức thay vì spinner tròn giữa page — UX mượt hơn nhiều.
class ReservationCardSkeleton extends StatelessWidget {
  const ReservationCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: AppRadius.radiusLgAll,
        border: Border.all(color: colors.outlineVariant),
        boxShadow: const [],
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          // Avatar placeholder 48x48
          AppShimmer.boxRadius(
            context: context,
            width: 48,
            height: 48,
            borderRadius: AppRadius.radiusMdAll,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppShimmer.boxRadius(
                  context: context,
                  width: double.infinity,
                  height: 14,
                  borderRadius: AppRadius.radiusXxsAll,
                ),
                const SizedBox(height: AppSpacing.sm),
                AppShimmer.boxRadius(
                  context: context,
                  width: 160,
                  height: 12,
                  borderRadius: AppRadius.radiusXxsAll,
                ),
                const SizedBox(height: AppSpacing.xs),
                AppShimmer.boxRadius(
                  context: context,
                  width: 120,
                  height: 12,
                  borderRadius: AppRadius.radiusXxsAll,
                ),
                const SizedBox(height: AppSpacing.xs),
                AppShimmer.boxRadius(
                  context: context,
                  width: 200,
                  height: 12,
                  borderRadius: AppRadius.radiusXxsAll,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}