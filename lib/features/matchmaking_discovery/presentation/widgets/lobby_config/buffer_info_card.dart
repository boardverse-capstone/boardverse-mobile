import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/neo_brutalism_theme.dart';

/// Neo-brutalism Buffer info card.
class LobbyConfigBufferInfoCard extends StatelessWidget {
  final int bufferMinutes;
  final bool isBufferTooShort;
  final String Function(int) formatBuffer;

  const LobbyConfigBufferInfoCard({
    super.key,
    required this.bufferMinutes,
    required this.isBufferTooShort,
    required this.formatBuffer,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (bufferMinutes < 0) {
      return Container(
        padding: AppSpacing.paddingAllMd,
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.error,
            width: NeoBrutalismTheme.borderWidthBold,
          ),
          boxShadow: NeoBrutalismTheme.lightShadow(
            shadowColor: AppColors.error.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.error,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.event_busy,
                color: AppColors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'THỜI GIAN TUYỂN NGƯỜI',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.outline,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Ngày bạn chọn đã qua. Vui lòng chọn ngày khác.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.error,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final color = isBufferTooShort
        ? AppColors.error
        : bufferMinutes >= 120
            ? AppColors.success
            : AppColors.warning;
    final icon = isBufferTooShort
        ? Icons.error
        : bufferMinutes >= 120
            ? Icons.check_circle
            : Icons.warning;

    return Container(
      padding: AppSpacing.paddingAllMd,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: color,
          width: NeoBrutalismTheme.borderWidthBold,
        ),
        boxShadow: NeoBrutalismTheme.lightShadow(
          shadowColor: color.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: AppColors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'THỜI GIAN TUYỂN NGƯỜI',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.outline,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  formatBuffer(bufferMinutes),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: color,
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
