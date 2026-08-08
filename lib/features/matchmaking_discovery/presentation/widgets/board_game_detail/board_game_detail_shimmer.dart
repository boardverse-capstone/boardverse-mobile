import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/neo_brutalism_theme.dart';

/// Neo-brutalism Shimmer skeleton cho [BoardGameDetailPage].
class BoardGameDetailShimmer extends StatelessWidget {
  const BoardGameDetailShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark
        ? AppColors.surfaceDark
        : AppColors.surfaceVariant;
    final highlight = isDark
        ? AppColors.surfaceElevatedDark
        : AppColors.surface;
    final borderColor = isDark ? AppColors.borderDark : AppColors.border;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlight,
      period: const Duration(milliseconds: 1400),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero image
            _neoBox(height: 240, borderRadius: 16, borderColor: borderColor),
            const SizedBox(height: AppSpacing.md),

            // Game title + rating
            Row(
              children: [
                Expanded(
                  child: _neoBox(
                    height: 24,
                    borderRadius: 8,
                    borderColor: borderColor,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                _neoBox(
                  width: 60,
                  height: 24,
                  borderRadius: 8,
                  borderColor: borderColor,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),

            // Category chips
            Row(
              children: List.generate(3, (i) => i)
                  .map((i) => Padding(
                        padding: EdgeInsets.only(
                          right: i < 2 ? AppSpacing.xs : 0,
                        ),
                        child: _neoBox(
                          width: 70,
                          height: 28,
                          borderRadius: 14,
                          borderColor: borderColor,
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: AppSpacing.md),

            // Info section header
            _neoBox(
              width: 100,
              height: 16,
              borderRadius: 6,
              borderColor: borderColor,
            ),
            const SizedBox(height: AppSpacing.sm),

            // Info rows
            for (int i = 0; i < 4; i++) ...[
              Container(
                width: double.infinity,
                height: 14,
                margin: const EdgeInsets.only(bottom: AppSpacing.xs),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: borderColor,
                    width: NeoBrutalismTheme.borderWidth,
                  ),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.md),

            // Description header
            _neoBox(
              width: 80,
              height: 16,
              borderRadius: 6,
              borderColor: borderColor,
            ),
            const SizedBox(height: AppSpacing.sm),

            // Description lines
            for (int i = 0; i < 5; i++) ...[
              Container(
                width: double.infinity,
                height: 12,
                margin: const EdgeInsets.only(bottom: 6),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: borderColor,
                    width: NeoBrutalismTheme.borderWidth,
                  ),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),

            // Nearby cafes header
            _neoBox(
              width: 140,
              height: 18,
              borderRadius: 6,
              borderColor: borderColor,
            ),
            const SizedBox(height: AppSpacing.sm),

            // Cafe cards
            for (int i = 0; i < 2; i++) ...[
              Container(
                padding: AppSpacing.paddingAllMd,
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: baseColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: borderColor,
                    width: NeoBrutalismTheme.borderWidth,
                  ),
                ),
                child: Row(
                  children: [
                    _neoBox(
                      width: 56,
                      height: 56,
                      borderRadius: 10,
                      borderColor: borderColor,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _neoBox(
                            height: 14,
                            borderRadius: 6,
                            borderColor: borderColor,
                          ),
                          const SizedBox(height: 6),
                          _neoBox(
                            width: 120,
                            height: 12,
                            borderRadius: 4,
                            borderColor: borderColor,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: AppSpacing.huge + AppSpacing.lg),
          ],
        ),
      ),
    );
  }

  Widget _neoBox({
    double? width,
    required double height,
    double borderRadius = 0,
    required Color borderColor,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: borderColor,
          width: NeoBrutalismTheme.borderWidth,
        ),
      ),
    );
  }
}
