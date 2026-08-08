import 'package:flutter/material.dart';

import 'package:boardverse_mobile/core/theme/app_colors.dart';
import 'package:boardverse_mobile/core/theme/app_icons.dart';
import 'package:boardverse_mobile/core/theme/app_spacing.dart';
import 'package:boardverse_mobile/core/theme/neo_brutalism_theme.dart';
import 'package:boardverse_mobile/features/tournament/domain/entities/tournament_entity.dart';
import 'package:boardverse_mobile/features/tournament/presentation/utils/tournament_utils.dart';

/// Neo-brutalism Tournament detail info card.
class TournamentDetailInfo extends StatelessWidget {
  final TournamentEntity tournament;

  const TournamentDetailInfo({
    super.key,
    required this.tournament,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.borderDark : AppColors.border;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'THÔNG TIN GIẢI ĐẤU',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.surface,
            border: Border.all(color: borderColor, width: NeoBrutalismTheme.borderWidth),
            borderRadius: BorderRadius.circular(16),
            boxShadow: NeoBrutalismTheme.lightShadow(
              shadowColor: AppColors.black.withValues(alpha: 0.06),
            ),
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
                emphasized: !tournament.isFree,
              ),
              if (tournament.hasPrizePool)
                _InfoRow(
                  icon: AppIcons.level,
                  label: 'Tổng giải thưởng',
                  value: '${TournamentUtils.formatVnd(tournament.prizePool)}đ',
                  emphasized: true,
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
  final bool emphasized;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accentColor = emphasized ? AppColors.primary : theme.colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: accentColor, width: 1.5),
            ),
            child: Icon(icon, size: AppIcons.sm, color: accentColor),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              label.toUpperCase(),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color: emphasized ? accentColor : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}