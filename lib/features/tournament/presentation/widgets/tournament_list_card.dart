import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/tournament_entity.dart';
import '../../domain/entities/tournament_status.dart';

class TournamentListCard extends StatelessWidget {
  final TournamentEntity tournament;
  final VoidCallback? onTap;

  const TournamentListCard({
    super.key,
    required this.tournament,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFmt = DateFormat('dd/MM/yyyy');
    final timeFmt = DateFormat('HH:mm');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.emoji_events_outlined,
                      size: 32,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tournament.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${tournament.gameName} · ${tournament.cafeName}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _StatusChip(status: tournament.status),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _MetaItem(
                    icon: Icons.calendar_today_outlined,
                    label: dateFmt.format(tournament.startDate),
                  ),
                  const SizedBox(width: 12),
                  _MetaItem(
                    icon: Icons.schedule,
                    label: timeFmt.format(tournament.startDate),
                  ),
                  const Spacer(),
                  if (tournament.entryFee != null && tournament.entryFee! > 0)
                    _MetaItem(
                      icon: Icons.payments_outlined,
                      label: '${_formatVnd(tournament.entryFee!)}đ',
                    )
                  else
                    _MetaItem(
                      icon: Icons.local_offer_outlined,
                      label: 'Miễn phí',
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.people, size: 16, color: theme.colorScheme.outline),
                  const SizedBox(width: 6),
                  Text(
                    '${tournament.currentParticipants}/${tournament.maxParticipants} người tham gia',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(width: 12),
                  if (tournament.requiresElo) ...[
                    Icon(Icons.trending_up,
                        size: 16, color: theme.colorScheme.outline),
                    const SizedBox(width: 4),
                    Text(
                      'ELO ≥ ${tournament.minEloRequired}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: tournament.fillRatio,
                  minHeight: 6,
                  backgroundColor:
                      theme.colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _progressColor(tournament.status, theme),
                  ),
                ),
              ),
              if (tournament.prizePool > 0) ...[
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.tertiaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.workspace_premium,
                          size: 18,
                          color: theme.colorScheme.onTertiaryContainer),
                      const SizedBox(width: 6),
                      Text(
                        'Tổng giải thưởng: ${_formatVnd(tournament.prizePool)}đ',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onTertiaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatVnd(int value) {
    final s = value.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buffer.write('.');
      buffer.write(s[i]);
    }
    return buffer.toString();
  }

  Color _progressColor(TournamentStatus status, ThemeData theme) {
    switch (status) {
      case TournamentStatus.upcoming:
        return theme.colorScheme.tertiary;
      case TournamentStatus.registrationOpen:
        return theme.colorScheme.primary;
      case TournamentStatus.ongoing:
        return Colors.orange;
      case TournamentStatus.finished:
        return theme.colorScheme.outline;
    }
  }
}

class _StatusChip extends StatelessWidget {
  final TournamentStatus status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = _color(context, status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon(status), size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            status.label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Color _color(BuildContext context, TournamentStatus status) {
    switch (status) {
      case TournamentStatus.upcoming:
        return Colors.blueAccent;
      case TournamentStatus.registrationOpen:
        return Colors.green;
      case TournamentStatus.ongoing:
        return Colors.orange;
      case TournamentStatus.finished:
        return Theme.of(context).colorScheme.outline;
    }
  }

  IconData _icon(TournamentStatus status) {
    switch (status) {
      case TournamentStatus.upcoming:
        return Icons.schedule;
      case TournamentStatus.registrationOpen:
        return Icons.how_to_reg;
      case TournamentStatus.ongoing:
        return Icons.play_arrow;
      case TournamentStatus.finished:
        return Icons.flag_outlined;
    }
  }
}

class _MetaItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.outline),
        const SizedBox(width: 4),
        Text(label, style: theme.textTheme.bodySmall),
      ],
    );
  }
}
