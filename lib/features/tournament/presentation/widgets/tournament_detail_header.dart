import 'package:flutter/material.dart';

import 'package:boardverse_mobile/core/theme/app_colors.dart';
import 'package:boardverse_mobile/core/theme/app_icons.dart';
import 'package:boardverse_mobile/core/theme/app_spacing.dart';
import 'package:boardverse_mobile/features/tournament/domain/entities/tournament_entity.dart';

/// Neo-brutalism Tournament detail header (dùng trong bottom sheet).
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
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.secondary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.black, width: 2),
            boxShadow: const [
              BoxShadow(
                color: AppColors.black,
                blurRadius: 0,
                offset: Offset(2, 2),
              ),
            ],
          ),
          child: const Icon(
            AppIcons.tournament,
            size: AppIcons.xl,
            color: AppColors.white,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tournament.title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                '${tournament.gameTemplateName} · ${tournament.cafeName}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.black, width: 2),
            boxShadow: const [
              BoxShadow(
                color: AppColors.black,
                blurRadius: 0,
                offset: Offset(2, 2),
              ),
            ],
          ),
          child: IconButton(
            tooltip: 'Đóng',
            onPressed: onClose,
            icon: const Icon(AppIcons.close, color: AppColors.black, size: 18),
          ),
        ),
      ],
    );
  }
}