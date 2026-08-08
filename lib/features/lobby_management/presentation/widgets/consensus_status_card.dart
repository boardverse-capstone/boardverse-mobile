import 'package:flutter/material.dart';

import 'package:boardverse_mobile/core/theme/app_colors.dart';
import 'package:boardverse_mobile/core/theme/app_icons.dart';
import 'package:boardverse_mobile/core/theme/app_spacing.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final progress = result.requiredCount > 0
        ? result.submittedCount / result.requiredCount
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.border,
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.4),
            blurRadius: 0,
            offset: const Offset(4, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.xs),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDark
                        ? AppColors.borderDark
                        : AppColors.border,
                    width: 2,
                  ),
                ),
                child: const Icon(
                  AppIcons.rating,
                  size: 18,
                  color: AppColors.white,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Trạng thái đồng thuận',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimary,
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
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 10,
                        backgroundColor: AppColors.textTertiary
                            .withValues(alpha: 0.2),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _getStatusColor(result.consensusStatus),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '${result.submittedCount}/${result.requiredCount} đã gửi',
                      style: TextStyle(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
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
                color: AppColors.warning,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDark
                      ? AppColors.borderDark
                      : AppColors.border,
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.black,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.warning_amber_rounded,
                      size: 18,
                      color: AppColors.warning,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Kết quả mâu thuẫn',
                          style: TextStyle(
                            color: AppColors.black,
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                          ),
                        ),
                        if (result.conflictReason != null)
                          Text(
                            result.conflictReason!,
                            style: TextStyle(
                              color: AppColors.black,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
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
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 14,
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          ...result.submissions.map(
            (submission) => _SubmissionItem(
              submission: submission,
              currentUserId: currentUserId,
              isDark: isDark,
            ),
          ),

          if (result.submissions.isEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Center(
              child: Text(
                'Chưa có ai gửi kết quả',
                style: TextStyle(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondary,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ],
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
    final (color, fg, label) = switch (status) {
      ConsensusStatus.awaitingSubmissions => (
        AppColors.warning,
        AppColors.black,
        'Chờ',
      ),
      ConsensusStatus.conflict => (
        AppColors.error,
        AppColors.white,
        'Mâu thuẫn',
      ),
      ConsensusStatus.finalized => (
        AppColors.success,
        AppColors.white,
        'Hoàn tất',
      ),
    };

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.border,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.3),
            blurRadius: 0,
            offset: const Offset(2, 2),
          ),
        ],
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _SubmissionItem extends StatelessWidget {
  final MatchSubmissionEntity submission;
  final String currentUserId;
  final bool isDark;

  const _SubmissionItem({
    required this.submission,
    required this.currentUserId,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final (outcomeColor, fg, outcomeIcon) =
        switch (submission.outcome) {
      MatchOutcome.win => (
        AppColors.success,
        AppColors.white,
        Icons.emoji_events,
      ),
      MatchOutcome.loss => (
        AppColors.error,
        AppColors.white,
        Icons.sentiment_dissatisfied,
      ),
      MatchOutcome.draw => (
        AppColors.info,
        AppColors.white,
        Icons.handshake,
      ),
      null => (
        AppColors.textTertiary,
        AppColors.white,
        Icons.help_outline,
      ),
    };

    final isCurrentUser = submission.isCurrentUser ||
        submission.odId == currentUserId;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isCurrentUser ? AppColors.primary : AppColors.secondary,
              shape: BoxShape.circle,
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.border,
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                submission.username.isNotEmpty
                    ? submission.username[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  color: AppColors.white,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              isCurrentUser
                  ? '${submission.username} (Bạn)'
                  : submission.username,
              style: TextStyle(
                fontWeight: isCurrentUser
                    ? FontWeight.w900
                    : FontWeight.w700,
                fontSize: 13,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimary,
              ),
            ),
          ),
          if (submission.outcome != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xxs,
              ),
              decoration: BoxDecoration(
                color: outcomeColor,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isDark
                      ? AppColors.borderDark
                      : AppColors.border,
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(outcomeIcon, size: 14, color: fg),
                  const SizedBox(width: 4),
                  Text(
                    submission.outcome!.label,
                    style: TextStyle(
                      color: fg,
                      fontWeight: FontWeight.w900,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            Text(
              'Chưa gửi',
              style: TextStyle(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondary,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Widget hiển thị thay thế Elo - neo-brutalism style.
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isGain = eloUpdate.isGain;
    final color = isGain ? AppColors.success : AppColors.error;
    final deltaText = eloUpdate.eloDelta > 0
        ? '+${eloUpdate.eloDelta}'
        : '${eloUpdate.eloDelta}';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isCurrentUser
              ? AppColors.primary
              : (isDark ? AppColors.borderDark : AppColors.border),
          width: isCurrentUser ? 3 : 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.4),
            blurRadius: 0,
            offset: const Offset(3, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.border,
                width: 2,
              ),
            ),
            child: Icon(
              isGain ? Icons.trending_up : Icons.trending_down,
              size: 20,
              color: AppColors.white,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isCurrentUser ? 'Elo của bạn' : 'Elo',
                  style: TextStyle(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      '${eloUpdate.eloBefore}',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    const Icon(Icons.arrow_forward,
                        size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      '${eloUpdate.eloAfter}',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimary,
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
              color: color,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.border,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.black.withValues(alpha: 0.3),
                  blurRadius: 0,
                  offset: const Offset(2, 2),
                ),
              ],
            ),
            child: Text(
              deltaText,
              style: const TextStyle(
                color: AppColors.white,
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}