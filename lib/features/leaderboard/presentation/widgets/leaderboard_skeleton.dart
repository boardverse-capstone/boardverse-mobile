import 'package:flutter/material.dart';

import 'package:boardverse/core/theme/app_colors.dart';
import 'package:boardverse/core/theme/app_spacing.dart';
import 'package:boardverse/core/theme/neo_brutalism_theme.dart';
import 'package:boardverse/core/widgets/shimmer_skeletons.dart';

/// Loading skeleton cho toàn bộ leaderboard page — header card + 6 row.
///
/// Theo Neo-Brutalism: khung card có border đậm + hard shadow giả lập
/// bằng cách dùng dark variant mà không có shimmer bên trong (placeholder
/// trống), shimmer chỉ áp dụng cho nội dung text/avatar.
class LeaderboardPageSkeleton extends StatelessWidget {
  const LeaderboardPageSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        _PodiumSkeleton(),
        const SizedBox(height: AppSpacing.md),
        for (var i = 0; i < 6; i++) ...[
          const _RowTileSkeleton(),
          if (i < 5) const SizedBox(height: AppSpacing.xs),
        ],
      ],
    );
  }
}

class _PodiumSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: NeoBrutalismTheme.autoBox(
        context,
        backgroundColor: AppColors.accent.withValues(alpha: 0.10),
        borderColor: AppColors.accent,
        borderRadius: 20,
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(child: _PodiumAvatarSkeleton(size: 64, height: 84)),
              Expanded(child: _PodiumAvatarSkeleton(size: 84, height: 112)),
              Expanded(child: _PodiumAvatarSkeleton(size: 64, height: 68)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          const ShimmerBase(width: 140, height: 12, radius: 4),
        ],
      ),
    );
  }
}

class _PodiumAvatarSkeleton extends StatelessWidget {
  final double size;
  final double height;
  const _PodiumAvatarSkeleton({required this.size, required this.height});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ShimmerBase(
          width: size,
          height: size,
          radius: size / 2,
        ),
        const SizedBox(height: AppSpacing.md),
        ShimmerBase(width: size - 8, height: 12, radius: 4),
        const SizedBox(height: AppSpacing.xs),
        ShimmerBase(width: size - 16, height: 10, radius: 4),
        const SizedBox(height: AppSpacing.xs),
        ShimmerBase(width: double.infinity, height: height, radius: 8),
      ],
    );
  }
}

class _RowTileSkeleton extends StatelessWidget {
  const _RowTileSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: NeoBrutalismTheme.autoBox(
        context,
        borderRadius: 14,
      ),
      child: Row(
        children: [
          const ShimmerBase(width: 44, height: 44, radius: 22),
          const SizedBox(width: AppSpacing.md),
          const ShimmerBase(width: 52, height: 52, radius: 26),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                ShimmerBase(width: double.infinity, height: 14, radius: 4),
                SizedBox(height: 6),
                ShimmerBase(width: 120, height: 12, radius: 4),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          const ShimmerBase(width: 56, height: 24, radius: 6),
        ],
      ),
    );
  }
}
