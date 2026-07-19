import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';
import '../../domain/entities/rating_entity.dart';

class EloResultDisplayWidget extends StatelessWidget {
  final EloResult eloResult;
  final VoidCallback? onViewLeaderboard;
  final VoidCallback? onComplete;

  const EloResultDisplayWidget({
    super.key,
    required this.eloResult,
    this.onViewLeaderboard,
    this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isPositive = eloResult.eloChange >= 0;
    final changeColor = isPositive ? colors.tertiary : colors.error;
    final resultText = switch (eloResult.result) {
      MatchResult.win => 'Thắng',
      MatchResult.lose => 'Thua',
      MatchResult.draw => 'Hòa',
    };
    final resultIcon = switch (eloResult.result) {
      MatchResult.win => Icons.emoji_events_outlined,
      MatchResult.lose => Icons.sentiment_dissatisfied_outlined,
      MatchResult.draw => Icons.handshake_outlined,
    };
    final resultBg = switch (eloResult.result) {
      MatchResult.win => colors.tertiaryContainer,
      MatchResult.lose => colors.surfaceContainerHighest,
      MatchResult.draw => colors.secondaryContainer,
    };
    final resultFg = switch (eloResult.result) {
      MatchResult.win => colors.onTertiaryContainer,
      MatchResult.lose => colors.onSurfaceVariant,
      MatchResult.draw => colors.onSecondaryContainer,
    };

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: AppRadius.cardRadius,
        border: Border.all(color: colors.outlineVariant),
        boxShadow: AppElevation.shadowMd,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(color: resultBg, shape: BoxShape.circle),
            child: Icon(resultIcon, size: AppIcons.massive, color: resultFg),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            resultText,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: resultFg,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Điểm Elo của bạn biến động như sau:',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: changeColor.withValues(alpha: 0.1),
              borderRadius: AppRadius.radiusMdAll,
              border: Border.all(color: changeColor.withValues(alpha: 0.32)),
            ),
            child: Column(
              children: [
                Text(
                  'Điểm Elo biến động',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: changeColor,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.xs),
                      decoration: BoxDecoration(
                        color: changeColor.withValues(alpha: 0.18),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isPositive
                            ? Icons.arrow_upward_rounded
                            : Icons.arrow_downward_rounded,
                        color: changeColor,
                        size: AppIcons.lg,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      '${eloResult.eloChange.abs()}',
                      style: theme.textTheme.displaySmall?.copyWith(
                        color: changeColor,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: AppRadius.radiusMdAll,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${eloResult.currentElo}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                          decoration: TextDecoration.lineThrough,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Icon(
                        AppIcons.forward,
                        size: AppIcons.md,
                        color: colors.onSurfaceVariant,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        '${eloResult.newElo}',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: colors.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          if (onViewLeaderboard != null) ...[
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onViewLeaderboard,
                icon: const Icon(AppIcons.rating),
                label: const Text('Xem Bảng xếp hạng'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          if (onComplete != null)
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onComplete,
                icon: const Icon(AppIcons.check),
                label: const Text('Hoàn tất'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
