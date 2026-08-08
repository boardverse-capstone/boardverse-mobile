import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/neo_brutalism_theme.dart';

/// Danh sách skeleton cho trang danh sách game — Neo-brutalism style.
class GameSkeletonList extends StatelessWidget {
  final int itemCount;

  const GameSkeletonList({super.key, this.itemCount = 6});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? AppColors.surfaceDark : AppColors.surfaceVariant;
    final highlight = isDark
        ? AppColors.surfaceElevatedDark
        : AppColors.surface;
    final borderColor = isDark ? AppColors.borderDark : AppColors.border;

    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: highlight,
      period: const Duration(milliseconds: 1400),
      child: ListView.builder(
        padding: AppSpacing.paddingAllMd,
        itemCount: itemCount,
        itemBuilder: (context, index) => _GameSkeletonCard(
          borderColor: borderColor,
        ),
      ),
    );
  }
}

class _GameSkeletonCard extends StatelessWidget {
  const _GameSkeletonCard({required this.borderColor});

  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor,
          width: NeoBrutalismTheme.borderWidth,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 4 / 3,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(14),
                ),
              ),
            ),
          ),
          Padding(
            padding: AppSpacing.paddingAllSm,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: AppSpacing.md,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: AppSpacing.sm,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Container(
                        height: AppSpacing.sm,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Container(
                  height: AppSpacing.md,
                  width: AppSpacing.xxxl * 2,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(AppSpacing.huge),
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

/// Skeleton cho trang chi tiết game — Neo-brutalism style.
class GameDetailSkeleton extends StatelessWidget {
  const GameDetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? AppColors.surfaceDark : AppColors.surfaceVariant;
    final highlight = isDark
        ? AppColors.surfaceElevatedDark
        : AppColors.surface;
    final borderColor = isDark ? AppColors.borderDark : AppColors.border;

    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: highlight,
      period: const Duration(milliseconds: 1400),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            height: AppSpacing.huge * 3,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              border: Border(
                bottom: BorderSide(
                  color: borderColor,
                  width: NeoBrutalismTheme.borderWidth,
                ),
              ),
            ),
          ),
          Padding(
            padding: AppSpacing.paddingAllMd,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: AppSpacing.lg,
                  width: AppSpacing.xxxl * 3,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Container(
                  height: AppSpacing.md,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Container(
                  height: AppSpacing.md,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Container(
                  height: AppSpacing.md,
                  width: AppSpacing.xxxl * 4,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Container(
                  height: AppSpacing.xxxl,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
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
