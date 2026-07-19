import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';
import '../cubit/voting_state.dart';

/// Widget hiển thị một candidate để vote no-show.
class VotingCard extends StatefulWidget {
  final VotingCandidate candidate;
  final int noShowVotes;
  final int notNoShowVotes;
  final int totalVoters;
  final Duration remainingTime;
  final VoidCallback onVoteNoShow;
  final VoidCallback onVoteNotNoShow;
  final VoidCallback onSkip;

  const VotingCard({
    super.key,
    required this.candidate,
    required this.noShowVotes,
    required this.notNoShowVotes,
    required this.totalVoters,
    required this.remainingTime,
    required this.onVoteNoShow,
    required this.onVoteNotNoShow,
    required this.onSkip,
  });

  @override
  State<VotingCard> createState() => _VotingCardState();
}

class _VotingCardState extends State<VotingCard> {
  String _formatDuration(Duration d) {
    if (d.isNegative) return '0s';
    final seconds = d.inSeconds;
    return '${seconds}s';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final progress = widget.totalVoters > 0
        ? (widget.noShowVotes + widget.notNoShowVotes) / widget.totalVoters
        : 0.0;
    final isUrgent = widget.remainingTime.inSeconds <= 10;
    final urgentColor = colors.error;
    final normalColor = theme.brightness == Brightness.dark
        ? AppColorsDark.info
        : AppColors.info;
    final timerColor = isUrgent ? urgentColor : normalColor;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: AppRadius.cardRadius,
        border: Border.all(color: colors.outlineVariant),
        boxShadow: AppElevation.shadowXs,
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: colors.secondaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        widget.candidate.name.isEmpty
                            ? '?'
                            : widget.candidate.name.characters.first
                                  .toUpperCase(),
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: colors.onSecondaryContainer,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  if (widget.candidate.isHost)
                    Positioned(
                      right: -4,
                      bottom: -4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xs,
                          vertical: AppSpacing.xxs,
                        ),
                        decoration: BoxDecoration(
                          color: colors.tertiary,
                          borderRadius: AppRadius.radiusXxsAll,
                          border: Border.all(color: colors.surface, width: 1.5),
                        ),
                        child: Text(
                          'Host',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colors.onTertiary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.candidate.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      'Người có thể vắng mặt',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: timerColor.withValues(alpha: 0.12),
                  borderRadius: AppRadius.radiusFullAll,
                  border: Border.all(color: timerColor.withValues(alpha: 0.28)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(AppIcons.clock, size: AppIcons.sm, color: timerColor),
                    const SizedBox(width: AppSpacing.xxs),
                    Text(
                      _formatDuration(widget.remainingTime),
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: timerColor,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Tiến độ bình chọn',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${widget.noShowVotes + widget.notNoShowVotes}/${widget.totalVoters} đã vote',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              ClipRRect(
                borderRadius: AppRadius.radiusFullAll,
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: colors.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          Row(
            children: [
              Expanded(
                child: _VoteButton(
                  icon: AppIcons.busy,
                  label: 'Vắng mặt',
                  color: colors.error,
                  voteCount: widget.noShowVotes,
                  onTap: widget.onVoteNoShow,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: _VoteButton(
                  icon: AppIcons.available,
                  label: 'Có đến',
                  color: colors.tertiary,
                  voteCount: widget.notNoShowVotes,
                  onTap: widget.onVoteNotNoShow,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              _VoteButton(
                icon: Icons.skip_next,
                label: 'Bỏ qua',
                color: colors.onSurfaceVariant,
                voteCount: null,
                onTap: widget.onSkip,
                isSmall: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _VoteButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final int? voteCount;
  final VoidCallback onTap;
  final bool isSmall;

  const _VoteButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.voteCount,
    required this.onTap,
    this.isSmall = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: color.withValues(alpha: 0.1),
      borderRadius: AppRadius.radiusMdAll,
      child: InkWell(
        borderRadius: AppRadius.radiusMdAll,
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(
            vertical: isSmall ? AppSpacing.sm : AppSpacing.md,
            horizontal: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            borderRadius: AppRadius.radiusMdAll,
            border: Border.all(color: color.withValues(alpha: 0.32)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: isSmall ? AppIcons.md : AppIcons.xl,
                color: color,
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              if (voteCount != null) ...[
                const SizedBox(height: AppSpacing.xxs),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.18),
                    borderRadius: AppRadius.radiusFullAll,
                  ),
                  child: Text(
                    '$voteCount',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
