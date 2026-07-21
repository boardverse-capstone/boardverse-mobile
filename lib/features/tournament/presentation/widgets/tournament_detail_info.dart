import 'package:flutter/material.dart';

import 'package:boardverse_mobile/core/theme/theme.dart';
import 'package:boardverse_mobile/features/tournament/domain/entities/tournament_entity.dart';
import 'package:boardverse_mobile/features/tournament/presentation/utils/tournament_utils.dart';

class TournamentDetailInfo extends StatelessWidget {
  final TournamentEntity tournament;

  const TournamentDetailInfo({
    super.key,
    required this.tournament,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Thông tin giải đấu',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          decoration: BoxDecoration(
            border: Border.all(color: theme.colorScheme.outlineVariant),
            borderRadius: AppRadius.radiusMdAll,
          ),
          child: Column(
            children: [
              _InfoRow(
                icon: AppIcons.schedule,
                label: 'Bắt đầu',
                value: TournamentUtils.formatDateTime(tournament.startTime),
              ),
              _InfoRow(
                icon: AppIcons.schedule,
                label: 'Hạn đăng ký',
                value: TournamentUtils.formatDateTime(tournament.registrationDeadline),
              ),
              _InfoRow(
                icon: AppIcons.users,
                label: 'Người tham gia',
                value: '${tournament.currentParticipants}/${tournament.maxParticipants}',
              ),
              if (tournament.requiresKarma)
                _InfoRow(
                  icon: AppIcons.elo,
                  label: 'Karma tối thiểu',
                  value: '${tournament.minKarmaRequirement}',
                ),
              _InfoRow(
                icon: AppIcons.available,
                label: 'Phí tham gia',
                value: tournament.isFree ? 'Miễn phí' : '${TournamentUtils.formatVnd(tournament.registrationFee!)}đ',
              ),
              if (tournament.hasPrizePool)
                _InfoRow(
                  icon: AppIcons.level,
                  label: 'Tổng giải thưởng',
                  value: '${TournamentUtils.formatVnd(tournament.prizePool)}đ',
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Icon(icon, size: AppIcons.sm, color: theme.colorScheme.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
