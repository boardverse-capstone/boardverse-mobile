import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';

/// Shimmer placeholder cho quote preview.
///
/// Hiển thị khi đang chờ API `ReservationCubit.createQuote()` trả về,
/// thay vì `CircularProgressIndicator` thô. Đảm bảo UI không bị "chớp"
/// sang error/empty rồi mới load xong nội dung thật.
class LobbyConfigQuoteShimmer extends StatelessWidget {
  const LobbyConfigQuoteShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Shimmer.fromColors(
      baseColor: theme.colorScheme.surfaceContainerHighest,
      highlightColor: theme.colorScheme.surfaceContainerHigh,
      period: const Duration(milliseconds: 1400),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header (icon + title) ────────────────────────────────
          Container(
            padding: AppSpacing.paddingAllMd,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest
                  .withValues(alpha: 0.4),
              borderRadius: AppRadius.radiusMdAll,
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _shimmerBox(width: 24, height: 24),
                    const SizedBox(width: AppSpacing.sm),
                    _shimmerBox(width: 120, height: 18),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                const Divider(),
                const SizedBox(height: AppSpacing.sm),

                // 4 quote rows
                for (int i = 0; i < 4; i++) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _shimmerBox(width: 100, height: 12),
                        _shimmerBox(width: 60, height: 12),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: AppSpacing.sm),
                const Divider(),
                const SizedBox(height: AppSpacing.sm),

                // Final deposit highlight
                Container(
                  padding: AppSpacing.paddingAllMd,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: AppRadius.radiusSmAll,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _shimmerBox(width: 110, height: 14),
                      _shimmerBox(width: 80, height: 22),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.md),

                // Buffer info box
                Container(
                  padding: AppSpacing.paddingAllSm,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: AppRadius.radiusSmAll,
                  ),
                  child: Row(
                    children: [
                      _shimmerBox(width: 18, height: 18),
                      const SizedBox(width: AppSpacing.sm),
                      _shimmerBox(width: 200, height: 12),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _shimmerBox({required double width, required double height}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }
}