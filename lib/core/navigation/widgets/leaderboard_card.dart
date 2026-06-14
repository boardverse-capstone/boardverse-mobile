import 'package:flutter/material.dart';

class LeaderboardCard extends StatelessWidget {
  final Map<String, dynamic> player;
  final int rank;
  final String sortBy;
  final VoidCallback onTap;

  const LeaderboardCard({
    super.key,
    required this.player,
    required this.rank,
    required this.sortBy,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCurrentUser = player['isCurrentUser'] == true;

    return Card(
      clipBehavior: Clip.antiAlias,
      color: isCurrentUser
          ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
          : null,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              _buildRankBadge(context),
              const SizedBox(width: 12),
              CircleAvatar(
                radius: 24,
                backgroundColor: _getTierColor(player['tier'] ?? 'Bronze').withValues(alpha: 0.2),
                child: Text(
                  player['avatar'] ?? '?',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _getTierColor(player['tier'] ?? 'Bronze'),
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
                        Flexible(
                          child: Text(
                            player['username'] ?? 'Unknown',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isCurrentUser
                                  ? theme.colorScheme.primary
                                  : null,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isCurrentUser) ...[
                          const SizedBox(width: 4),
                          Icon(
                            Icons.person,
                            size: 16,
                            color: theme.colorScheme.primary,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _buildMiniStat(context, 'Lv.${player['level'] ?? 0}'),
                        const SizedBox(width: 8),
                        _buildMiniStat(context, player['tier'] ?? 'Bronze'),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _getDisplayValue(),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: _getValueColor(),
                    ),
                  ),
                  Text(
                    _getValueLabel(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRankBadge(BuildContext context) {
    final theme = Theme.of(context);
    
    if (rank <= 3) {
      return Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: _getRankColor(rank).withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Icon(
            Icons.emoji_events,
            color: _getRankColor(rank),
            size: 20,
          ),
        ),
      );
    }

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          '#$rank',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.outline,
          ),
        ),
      ),
    );
  }

  Widget _buildMiniStat(BuildContext context, String text) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.outline,
        ),
      ),
    );
  }

  String _getDisplayValue() {
    switch (sortBy) {
      case 'elo':
        return '${player['elo']}';
      case 'wins':
        return '${player['wins']}';
      case 'karma':
        return '${player['karma'] ?? player['wins']}';
      default:
        return '${player['elo']}';
    }
  }

  String _getValueLabel() {
    switch (sortBy) {
      case 'elo':
        return 'ELO';
      case 'wins':
        return 'Thắng';
      case 'karma':
        return 'Karma';
      default:
        return 'ELO';
    }
  }

  Color _getValueColor() {
    if (rank <= 3) {
      return _getRankColor(rank);
    }
    return Colors.grey.shade700;
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.amber.shade700;
      case 2:
        return Colors.grey.shade600;
      case 3:
        return Colors.brown.shade600;
      default:
        return Colors.grey;
    }
  }

  Color _getTierColor(String tier) {
    switch (tier) {
      case 'Diamond':
        return Colors.blue;
      case 'Platinum':
        return Colors.teal;
      case 'Gold':
        return Colors.amber.shade700;
      case 'Silver':
        return Colors.grey.shade600;
      case 'Bronze':
        return Colors.brown;
      default:
        return Colors.grey;
    }
  }
}
