import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/neo_brutalism_theme.dart';

/// Neo-brutalism Shimmer placeholder cho quote preview.
class LobbyConfigQuoteShimmer extends StatelessWidget {
  const LobbyConfigQuoteShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? AppColors.surfaceDark : AppColors.surfaceVariant;
    final highlight = isDark
        ? AppColors.surfaceElevatedDark
        : AppColors.surface;
    final borderColor =
        isDark ? AppColors.borderDark : AppColors.border;

    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: highlight,
      period: const Duration(milliseconds: 1400),
      child: Container(
        padding: AppSpacing.paddingAllMd,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: borderColor,
            width: NeoBrutalismTheme.borderWidth,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                _shimmerBox(width: 30, height: 30, borderRadius: 8),
                const SizedBox(width: AppSpacing.sm),
                _shimmerBox(width: 120, height: 18, borderRadius: 6),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            _shimmerBox(width: double.infinity, height: 2, borderRadius: 1),
            const SizedBox(height: AppSpacing.sm),

            for (int i = 0; i < 4; i++) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _shimmerBox(width: 100, height: 12, borderRadius: 4),
                    _shimmerBox(width: 60, height: 12, borderRadius: 4),
                  ],
                ),
              ),
            ],

            const SizedBox(height: AppSpacing.sm),
            _shimmerBox(width: double.infinity, height: 2, borderRadius: 1),
            const SizedBox(height: AppSpacing.sm),

            // Final deposit highlight
            Container(
              padding: AppSpacing.paddingAllMd,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _shimmerBox(width: 110, height: 14, borderRadius: 6),
                  _shimmerBox(width: 80, height: 22, borderRadius: 6),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            // Buffer info box
            Container(
              padding: AppSpacing.paddingAllSm,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  _shimmerBox(width: 18, height: 18, borderRadius: 9),
                  const SizedBox(width: AppSpacing.sm),
                  _shimmerBox(width: 200, height: 12, borderRadius: 4),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _shimmerBox({
    required double width,
    required double height,
    double borderRadius = 0,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}
