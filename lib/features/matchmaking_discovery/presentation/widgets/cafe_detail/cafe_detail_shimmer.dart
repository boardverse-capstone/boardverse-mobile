import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/neo_brutalism_theme.dart';

/// Neo-brutalism Shimmer skeleton cho [CafeDetailPage].
class CafeDetailShimmer extends StatelessWidget {
  const CafeDetailShimmer({super.key});

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
            _neoBox(height: 180, borderRadius: 16, borderColor: borderColor),
            const SizedBox(height: AppSpacing.md),

            // Cafe name
            _neoBox(
              width: double.infinity,
              height: 24,
              borderRadius: 8,
              borderColor: borderColor,
            ),
            const SizedBox(height: AppSpacing.xs),

            // Address
            _neoBox(
              width: 200,
              height: 14,
              borderRadius: 6,
              borderColor: borderColor,
            ),
            const SizedBox(height: AppSpacing.md),

            // Rating + distance row
            Row(
              children: [
                _neoBox(
                  width: 80,
                  height: 32,
                  borderRadius: 16,
                  borderColor: borderColor,
                ),
                const SizedBox(width: AppSpacing.sm),
                _neoBox(
                  width: 60,
                  height: 32,
                  borderRadius: 16,
                  borderColor: borderColor,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

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
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Row(
                  children: [
                    _neoBox(
                      width: 20,
                      height: 20,
                      borderRadius: 6,
                      borderColor: borderColor,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: _neoBox(
                        height: 14,
                        borderRadius: 6,
                        borderColor: borderColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),

            // Available games header
            _neoBox(
              width: 140,
              height: 16,
              borderRadius: 6,
              borderColor: borderColor,
            ),
            const SizedBox(height: AppSpacing.sm),

            // Game list
            for (int i = 0; i < 3; i++) ...[
              Container(
                padding: AppSpacing.paddingAllMd,
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: baseColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor, width: 2),
                ),
                child: Row(
                  children: [
                    _neoBox(
                      width: 48,
                      height: 48,
                      borderRadius: 8,
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
                            width: 100,
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
