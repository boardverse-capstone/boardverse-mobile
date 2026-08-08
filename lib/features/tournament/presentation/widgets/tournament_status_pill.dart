import 'package:flutter/material.dart';

import 'package:boardverse_mobile/core/theme/app_colors.dart';
import 'package:boardverse_mobile/core/theme/app_icons.dart';
import 'package:boardverse_mobile/core/theme/app_spacing.dart';
import 'package:boardverse_mobile/features/tournament/domain/entities/tournament_status.dart';

/// Neo-brutalism Tournament status pill.
class TournamentStatusPill extends StatelessWidget {
  final TournamentStatus status;

  const TournamentStatusPill({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.black, width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: AppColors.black,
            blurRadius: 0,
            offset: Offset(2, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_statusIcon(status), size: 12, color: AppColors.white),
          const SizedBox(width: AppSpacing.xs),
          Text(
            status.label.toUpperCase(),
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }

  static Color _statusColor(TournamentStatus status) {
    switch (status) {
      case TournamentStatus.upcoming:
        return AppColors.secondary;
      case TournamentStatus.registrationOpen:
        return AppColors.success;
      case TournamentStatus.registrationClosed:
        return AppColors.accent;
      case TournamentStatus.ongoing:
        return AppColors.primary;
      case TournamentStatus.completed:
        return AppColors.textSecondary;
      case TournamentStatus.cancelled:
        return AppColors.error;
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