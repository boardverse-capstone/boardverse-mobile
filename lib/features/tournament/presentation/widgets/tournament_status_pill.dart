import 'package:flutter/material.dart';

import 'package:boardverse_mobile/core/theme/theme.dart';
import 'package:boardverse_mobile/features/tournament/domain/entities/tournament_status.dart';

class TournamentStatusPill extends StatelessWidget {
  final TournamentStatus status;

  const TournamentStatusPill({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _statusColor(theme, status);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: AppRadius.chipRadius,
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_statusIcon(status), size: AppIcons.sm, color: color),
          const SizedBox(width: AppSpacing.xs),
          Text(
            status.label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  static Color _statusColor(ThemeData theme, TournamentStatus status) {
    switch (status) {
      case TournamentStatus.upcoming:
        return theme.colorScheme.secondary;
      case TournamentStatus.registrationOpen:
        return AppColors.success;
      case TournamentStatus.registrationClosed:
        return theme.colorScheme.tertiary;
      case TournamentStatus.ongoing:
        return theme.colorScheme.primary;
      case TournamentStatus.completed:
        return theme.colorScheme.onSurfaceVariant;
      case TournamentStatus.cancelled:
        return theme.colorScheme.error;
    }
  }

  static IconData _statusIcon(TournamentStatus status) {
    switch (status) {
      case TournamentStatus.upcoming:
        return AppIcons.pending;
      case TournamentStatus.registrationOpen:
        return AppIcons.userCheck;
      case TournamentStatus.registrationClosed:
        return AppIcons.lock;
      case TournamentStatus.ongoing:
        return Icons.play_circle_outline_rounded;
      case TournamentStatus.completed:
        return AppIcons.flag;
      case TournamentStatus.cancelled:
        return AppIcons.close;
    }
  }
}
