import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/neo_brutalism_theme.dart';

/// Neo-brutalism Shimmer skeleton cho [LobbyCafeSelectionPage].
class LobbyCafeSelectionShimmer extends StatelessWidget {
  const LobbyCafeSelectionShimmer({super.key});

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
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        children: [
          // Location banner shimmer
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Container(
              padding: AppSpacing.paddingAllMd,
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
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.xs,
            ),
            child: _neoBox(
              width: 120,
              height: 16,
              borderRadius: 6,
              borderColor: borderColor,
            ),
          ),

          // Cafe cards shimmer
          for (int i = 0; i < 3; i++) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.sm,
                0,
                AppSpacing.sm,
                AppSpacing.xs,
              ),
              child: Container(
                padding: AppSpacing.paddingAllMd,
                decoration: BoxDecoration(
                  color: baseColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: borderColor,
                    width: NeoBrutalismTheme.borderWidth,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _neoBox(
                          width: 48,
                          height: 48,
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
                    const SizedBox(height: AppSpacing.sm),
                    _neoBox(
                      height: 12,
                      borderRadius: 4,
                      borderColor: borderColor,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        _neoBox(
                          width: 60,
                          height: 12,
                          borderRadius: 4,
                          borderColor: borderColor,
                        ),
                        const Spacer(),
                        _neoBox(
                          width: 80,
                          height: 12,
                          borderRadius: 4,
                          borderColor: borderColor,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
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
