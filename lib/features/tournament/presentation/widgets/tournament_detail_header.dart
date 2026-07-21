import 'package:flutter/material.dart';

import 'package:boardverse_mobile/core/theme/theme.dart';
import 'package:boardverse_mobile/features/tournament/domain/entities/tournament_entity.dart';

class TournamentDetailHeader extends StatelessWidget {
  final TournamentEntity tournament;
  final VoidCallback onClose;

  const TournamentDetailHeader({
    super.key,
    required this.tournament,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tournament icon
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primary,
                theme.colorScheme.secondary,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: AppRadius.radiusMdAll,
          ),
          child: Icon(
            AppIcons.tournament,
            size: AppIcons.xl,
            color: theme.colorScheme.onPrimary,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        // Title and subtitle
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tournament.title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                '${tournament.gameTemplateName} · ${tournament.cafeName}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        // Close button
        IconButton(
          tooltip: 'Đóng',
          onPressed: onClose,
          icon: const Icon(AppIcons.close),
        ),
      ],
    );
  }
}
