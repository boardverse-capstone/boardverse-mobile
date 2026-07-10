import 'package:flutter/material.dart';

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
    final progress = widget.totalVoters > 0
        ? (widget.noShowVotes + widget.notNoShowVotes) / widget.totalVoters
        : 0.0;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Text(
                    widget.candidate.name[0].toUpperCase(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            widget.candidate.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (widget.candidate.isHost) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade100,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Host',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.amber.shade800,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Người có thể vắng mặt',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                ),
                // Countdown
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: widget.remainingTime.inSeconds <= 10
                        ? Colors.red.shade100
                        : Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.timer,
                        size: 16,
                        color: widget.remainingTime.inSeconds <= 10
                            ? Colors.red.shade700
                            : Colors.blue.shade700,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatDuration(widget.remainingTime),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: widget.remainingTime.inSeconds <= 10
                              ? Colors.red.shade700
                              : Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Progress indicator
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Tiến độ bình chọn',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                    Text(
                      '${widget.noShowVotes + widget.notNoShowVotes}/${widget.totalVoters} đã vote',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      theme.colorScheme.primary,
                    ),
                    minHeight: 8,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Vote buttons
            Row(
              children: [
                Expanded(
                  child: _VoteButton(
                    icon: Icons.person_off,
                    label: 'Vắng mặt',
                    color: Colors.red,
                    voteCount: widget.noShowVotes,
                    onTap: widget.onVoteNoShow,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _VoteButton(
                    icon: Icons.person,
                    label: 'Có đến',
                    color: Colors.green,
                    voteCount: widget.notNoShowVotes,
                    onTap: widget.onVoteNotNoShow,
                  ),
                ),
                const SizedBox(width: 8),
                _VoteButton(
                  icon: Icons.skip_next,
                  label: 'Bỏ qua',
                  color: Colors.grey,
                  voteCount: null,
                  onTap: widget.onSkip,
                  isSmall: true,
                ),
              ],
            ),
          ],
        ),
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
    this.voteCount,
    required this.onTap,
    this.isSmall = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.symmetric(
            vertical: isSmall ? 12 : 16,
            horizontal: 8,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: isSmall ? 20 : 28),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: isSmall ? 10 : 12,
                ),
                textAlign: TextAlign.center,
              ),
              if (voteCount != null) ...[
                const SizedBox(height: 2),
                Text(
                  '$voteCount',
                  style: TextStyle(
                    color: color.withValues(alpha: 0.7),
                    fontSize: 10,
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
