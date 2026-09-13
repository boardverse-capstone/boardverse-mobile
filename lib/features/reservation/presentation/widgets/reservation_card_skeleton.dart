import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shimmer.dart';
import '../../../../core/theme/app_spacing.dart';

/// Skeleton card cho danh sách reservation khi đang load.
///
/// Layout khớp 100% với `ReservationCardModern` (vertical 2-col grid):
///   - Cover shimmer 80px (gradient placeholder)
///   - Content padding 12/10/12/12
///   - Game name shimmer full-width (1 dòng)
///   - Cafe row shimmer (icon + text bar)
///   - Stats row shimmer — 2 dòng:
///       - Dòng 1: time + players (2 ô chia đều)
///       - Dòng 2: deposit (full-width — chỉ hiển thị khi có deposit)
///
/// Total height ≈ 220px khớp với `mainAxisExtent: 220` của grid.
///
/// Trước đây (Aug 2026 trở về trước) skeleton dùng layout horizontal
/// (avatar 48x48 + text bars) → không khớp với card dọc mới khiến cell
/// loading nhìn rất khác cell đã load.
class ReservationCardSkeleton extends StatelessWidget {
  const ReservationCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: AppRadius.radiusXlAll,
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.border,
          width: 1.5,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Cover shimmer (80px — match real card cover) ──────
          AppShimmer.box(
            context: context,
            height: 80,
            borderRadius: 0, // card đã clip border-radius 20px
          ),

          // ── Content (padding 12/10/12/12) ─────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Game name shimmer (1 dòng full-width) ──
                AppShimmer.boxRadius(
                  context: context,
                  width: double.infinity,
                  height: 14,
                  borderRadius: AppRadius.radiusXxsAll,
                ),

                const SizedBox(height: 6),

                // ── Cafe row shimmer (icon 12px + text bar) ─
                Row(
                  children: [
                    // Icon placeholder (12px giống real card)
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 3),
                    AppShimmer.boxRadius(
                      context: context,
                      width: 90,
                      height: 13,
                      borderRadius: AppRadius.radiusXxsAll,
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.xs),

                // ── Stats row 1: time + players (2 ô chia đều) ─
                Row(
                  children: [
                    Expanded(
                      child: AppShimmer.boxRadius(
                        context: context,
                        height: 14,
                        borderRadius: AppRadius.radiusXxsAll,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: AppShimmer.boxRadius(
                        context: context,
                        height: 14,
                        borderRadius: AppRadius.radiusXxsAll,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 6),

                // ── Stats row 2: deposit (full-width) ────────
                AppShimmer.boxRadius(
                  context: context,
                  width: double.infinity,
                  height: 14,
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