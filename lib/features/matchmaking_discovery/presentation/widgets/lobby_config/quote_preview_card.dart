import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/neo_brutalism_theme.dart';
import '../../../../reservation/domain/entities/entities.dart';
import 'quote_row.dart';

/// Neo-brutalism Quote preview card.
class LobbyConfigQuotePreviewCard extends StatelessWidget {
  final ReservationQuoteEntity quote;
  final String Function(int) formatBuffer;

  const LobbyConfigQuotePreviewCard({
    super.key,
    required this.quote,
    required this.formatBuffer,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: AppSpacing.paddingAllMd,
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary,
          width: NeoBrutalismTheme.borderWidthBold,
        ),
        boxShadow: NeoBrutalismTheme.lightShadow(
          shadowColor: AppColors.primary.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.payments,
                  color: AppColors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'CHI TIẾT CỌC',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Container(height: 2, color: AppColors.primary.withValues(alpha: 0.2)),
          const SizedBox(height: AppSpacing.sm),

          LobbyConfigQuoteRow(
            label: 'Tiền cọc/người',
            value: '${quote.depositRatePerPerson} BVC',
          ),
          LobbyConfigQuoteRow(
            label: 'Số người',
            value: quote.playerRangeDisplay,
          ),
          LobbyConfigQuoteRow(
            label: 'Base deposit',
            value: '${quote.baseDeposit} BVC',
          ),
          LobbyConfigQuoteRow(
            label: 'Risk multiplier',
            value: '${quote.riskMultiplier}x',
          ),

          const SizedBox(height: AppSpacing.sm),
          Container(height: 2, color: AppColors.primary.withValues(alpha: 0.2)),
          const SizedBox(height: AppSpacing.sm),

          // Final deposit highlight
          Container(
            padding: AppSpacing.paddingAllMd,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'TỔNG CỌC',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: AppColors.white,
                    fontSize: 13,
                    letterSpacing: 1,
                  ),
                ),
                Text(
                  '${quote.finalDeposit} BVC',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: AppColors.white,
                    fontSize: 22,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // Buffer info
          Container(
            padding: AppSpacing.paddingAllSm,
            decoration: BoxDecoration(
              color: _getBufferColor(
                quote.bufferWarningLevel,
              ).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _getBufferColor(quote.bufferWarningLevel),
                width: NeoBrutalismTheme.borderWidth,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _getBufferIcon(quote.bufferWarningLevel),
                  color: _getBufferColor(quote.bufferWarningLevel),
                  size: 18,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Buffer: ${formatBuffer(quote.bufferMinutes)} để tuyển người',
                  style: TextStyle(
                    color: _getBufferColor(quote.bufferWarningLevel),
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getBufferColor(BufferWarningLevel level) {
    switch (level) {
      case BufferWarningLevel.rejected:
        return AppColors.error;
      case BufferWarningLevel.warning:
        return AppColors.warning;
      case BufferWarningLevel.none:
        return AppColors.success;
    }
  }

  IconData _getBufferIcon(BufferWarningLevel level) {
    switch (level) {
      case BufferWarningLevel.rejected:
        return Icons.error;
      case BufferWarningLevel.warning:
        return Icons.warning;
      case BufferWarningLevel.none:
        return Icons.check_circle;
    }
  }
}
