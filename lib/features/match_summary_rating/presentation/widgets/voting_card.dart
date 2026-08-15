import 'package:flutter/material.dart';

import 'package:boardverse/core/theme/app_colors.dart';
import 'package:boardverse/core/theme/app_icons.dart';
import 'package:boardverse/core/theme/app_spacing.dart';
import '../cubit/voting_state.dart';

/// Neo-brutalism widget hiển thị một candidate để vote no-show.
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final progress = widget.totalVoters > 0
        ? (widget.noShowVotes + widget.notNoShowVotes) / widget.totalVoters
        : 0.0;
    final isUrgent = widget.remainingTime.inSeconds <= 10;
    final timerColor = isUrgent ? AppColors.error : AppColors.info;

    return Container(
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
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Avatar with optional host badge
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.secondary,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color:
                            isDark ? AppColors.borderDark : AppColors.border,
                        width: 2.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.black.withValues(alpha: 0.4),
                          blurRadius: 0,
                          offset: const Offset(2, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        widget.candidate.name.isEmpty
                            ? '?'
                            : widget.candidate.name.characters.first
                                .toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 22,
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
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: AppColors.black,
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.black.withValues(alpha: 0.3),
                              blurRadius: 0,
                              offset: const Offset(1, 1),
                            ),
                          ],
                        ),
                        child: const Text(
                          'HOST',
                          style: TextStyle(
                            color: AppColors.black,
                            fontWeight: FontWeight.w900,
                            fontSize: 9,
                            letterSpacing: 0.5,
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
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Người có thể vắng mặt',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              // Timer pill
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: timerColor,
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
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(AppIcons.clock,
                        size: 14, color: AppColors.white),
                    const SizedBox(width: 4),
                    Text(
                      _formatDuration(widget.remainingTime),
                      style: const TextStyle(
                        color: AppColors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          // Progress
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TIẾN ĐỘ BÌNH CHỌN',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                  letterSpacing: 0.8,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isDark
                        ? AppColors.borderDark
                        : AppColors.border,
                    width: 1.5,
                  ),
                ),
                child: Text(
                  '${widget.noShowVotes + widget.notNoShowVotes}/${widget.totalVoters}',
                  style: const TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: isDark
                  ? AppColors.borderDark
                  : AppColors.border,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.primary,
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          Row(
            children: [
              Expanded(
                child: _VoteButton(
                  icon: AppIcons.busy,
                  label: 'Vắng mặt',
                  color: AppColors.error,
                  voteCount: widget.noShowVotes,
                  onTap: widget.onVoteNoShow,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: _VoteButton(
                  icon: AppIcons.available,
                  label: 'Có đến',
                  color: AppColors.success,
                  voteCount: widget.notNoShowVotes,
                  onTap: widget.onVoteNotNoShow,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              _VoteButton(
                icon: Icons.skip_next,
                label: 'Bỏ qua',
                color: AppColors.textSecondary,
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

/// Neo-brutalism vote button.
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(
            vertical: isSmall ? AppSpacing.sm : AppSpacing.md,
            horizontal: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withValues(alpha: 0.4),
                blurRadius: 0,
                offset: const Offset(3, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: isSmall ? 18 : 28,
                color: AppColors.white,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
              if (voteCount != null) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.black,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: AppColors.white,
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    '$voteCount',
                    style: const TextStyle(
                      color: AppColors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 11,
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