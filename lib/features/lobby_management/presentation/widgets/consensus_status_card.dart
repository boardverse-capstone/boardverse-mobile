import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';
import '../../domain/entities/match_result_entity.dart';
import '../../domain/entities/elo_update_entity.dart';

/// Widget hiển thị trạng thái consensus của trận đấu.
class ConsensusStatusCard extends StatelessWidget {
  final MatchResultEntity result;
  final String currentUserId;

  const ConsensusStatusCard({
    super.key,
    required this.result,
    this.currentUserId = '',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final progress = result.requiredCount > 0
        ? result.submittedCount / result.requiredCount
        : 0.0;

    return Card(
      elevation: AppElevation.elevationSm,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.radiusLgAll,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  AppIcons.rating,
                  size: AppIcons.lg,
                  color: colors.primary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Trạng thái đồng thuận',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                _StatusChip(status: result.consensusStatus),
              ],
            ),

            const SizedBox(height: AppSpacing.md),

            // Progress bar
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: AppRadius.radiusFullAll,
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 8,
                          backgroundColor: colors.surfaceContainerHighest,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _getStatusColor(result.consensusStatus),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        '${result.submittedCount}/${result.requiredCount} đã gửi',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Conflict warning
            if (result.hasConflict) ...[
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: AppRadius.radiusSmAll,
                  border: Border.all(color: AppColors.warning),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      size: AppIcons.md,
                      color: AppColors.warning,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Kết quả mâu thuẫn',
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: AppColors.warning,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (result.conflictReason != null)
                            Text(
                              result.conflictReason!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.warning,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: AppSpacing.md),

            // Submissions list
            Text(
              'Kết quả đã gửi',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            ...result.submissions.map(
              (submission) => _SubmissionItem(
                submission: submission,
                currentUserId: currentUserId,
              ),
            ),

            if (result.submissions.isEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Center(
                child: Text(
                  'Chưa có ai gửi kết quả',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(ConsensusStatus status) {
    return switch (status) {
      ConsensusStatus.awaitingSubmissions => AppColors.warning,
      ConsensusStatus.conflict => AppColors.error,
      ConsensusStatus.finalized => AppColors.success,
    };
  }
}

class _StatusChip extends StatelessWidget {
  final ConsensusStatus status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (status) {
      ConsensusStatus.awaitingSubmissions =>
        (AppColors.warning, 'Chờ'),
      ConsensusStatus.conflict =>
        (AppColors.error, 'Mâu thuẫn'),
      ConsensusStatus.finalized =>
        (AppColors.success, 'Hoàn tất'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: AppRadius.radiusXxsAll,
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _SubmissionItem extends StatelessWidget {
  final MatchSubmissionEntity submission;
  final String currentUserId;

  const _SubmissionItem({
    required this.submission,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final (outcomeColor, outcomeIcon) = switch (submission.outcome) {
      MatchOutcome.win => (AppColors.success, Icons.emoji_events),
      MatchOutcome.loss => (AppColors.error, Icons.sentiment_dissatisfied),
      MatchOutcome.draw => (AppColors.info, Icons.handshake),
      null => (colors.onSurfaceVariant, Icons.help_outline),
    };

    final isCurrentUser = submission.isCurrentUser ||
        submission.odId == currentUserId;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: isCurrentUser
                ? colors.primaryContainer
                : colors.surfaceContainerHighest,
            child: Text(
              submission.username.isNotEmpty
                  ? submission.username[0].toUpperCase()
                  : '?',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              isCurrentUser ? '${submission.username} (Bạn)' : submission.username,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: isCurrentUser ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
          if (submission.outcome != null) ...[
            Icon(
              outcomeIcon,
              size: AppIcons.md,
              color: outcomeColor,
            ),
            const SizedBox(width: AppSpacing.xxs),
            Text(
              submission.outcome!.label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: outcomeColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ] else ...[
            Text(
              'Chưa gửi',
              style: theme.textTheme.labelSmall?.copyWith(
                color: colors.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Widget hiển thị thay đổi Elo.
class EloChangeDisplay extends StatelessWidget {
  final EloUpdateEntity eloUpdate;
  final bool isCurrentUser;

  const EloChangeDisplay({
    super.key,
    required this.eloUpdate,
    this.isCurrentUser = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isGain = eloUpdate.isGain;
    final color = isGain ? AppColors.success : AppColors.error;
    final deltaText = eloUpdate.eloDelta > 0
        ? '+${eloUpdate.eloDelta}'
        : '${eloUpdate.eloDelta}';

    return Card(
      elevation: AppElevation.elevationSm,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.radiusMdAll,
        side: isCurrentUser
            ? BorderSide(color: colors.primary, width: 2)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: color.withValues(alpha: 0.1),
              child: Icon(
                isGain ? Icons.trending_up : Icons.trending_down,
                size: AppIcons.md,
                color: color,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isCurrentUser ? 'Elo của bạn' : 'Elo',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        '${eloUpdate.eloBefore}',
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Icon(Icons.arrow_forward, size: AppIcons.sm, color: colors.onSurfaceVariant),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        '${eloUpdate.eloAfter}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xxs,
              ),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: AppRadius.radiusSmAll,
              ),
              child: Text(
                deltaText,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
