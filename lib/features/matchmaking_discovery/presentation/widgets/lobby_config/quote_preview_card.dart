import 'package:flutter/material.dart';

import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../reservation/domain/entities/entities.dart';
import 'quote_row.dart';

/// Quote preview card — render quote details + buffer warning.
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

    return Container(
      padding: AppSpacing.paddingAllMd,
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: AppRadius.radiusMdAll,
        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.payments, color: theme.colorScheme.primary),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Chi tiết cọc',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const Divider(),
          const SizedBox(height: AppSpacing.sm),

          LobbyConfigQuoteRow(
            label: 'Tiền cọc/người',
            value: '${quote.depositRatePerPerson} BVC',
          ),
          LobbyConfigQuoteRow(
            label: 'Số người',
            value: '${quote.minPlayers} - ${quote.maxPlayers}',
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
          const Divider(),
          const SizedBox(height: AppSpacing.sm),

          // Final deposit - highlight
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: AppRadius.radiusSmAll,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tổng cọc (final)',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${quote.finalDeposit} BVC',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // Buffer info
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: quote.bufferWarningLevel == BufferWarningLevel.rejected
                  ? Colors.red.withValues(alpha: 0.1)
                  : quote.bufferWarningLevel == BufferWarningLevel.warning
                      ? Colors.orange.withValues(alpha: 0.1)
                      : Colors.green.withValues(alpha: 0.1),
              borderRadius: AppRadius.radiusSmAll,
            ),
            child: Row(
              children: [
                Icon(
                  quote.bufferWarningLevel == BufferWarningLevel.rejected
                      ? Icons.error
                      : quote.bufferWarningLevel == BufferWarningLevel.warning
                          ? Icons.warning
                          : Icons.check_circle,
                  color: quote.bufferWarningLevel == BufferWarningLevel.rejected
                      ? Colors.red
                      : quote.bufferWarningLevel == BufferWarningLevel.warning
                          ? Colors.orange
                          : Colors.green,
                  size: 18,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Buffer: ${formatBuffer(quote.bufferMinutes)} để tuyển người',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: quote.bufferWarningLevel == BufferWarningLevel.rejected
                        ? Colors.red
                        : quote.bufferWarningLevel == BufferWarningLevel.warning
                            ? Colors.orange
                            : Colors.green,
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