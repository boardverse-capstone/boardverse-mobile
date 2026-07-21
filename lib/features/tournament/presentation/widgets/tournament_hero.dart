import 'package:flutter/material.dart';

import 'package:boardverse_mobile/core/theme/theme.dart';
import 'package:boardverse_mobile/features/tournament/presentation/cubit/tournament_list_state.dart';

class TournamentHero extends StatelessWidget {
  final TournamentListState state;

  const TournamentHero({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final onPrimary = theme.colorScheme.onPrimary;

    int totalCount = 0;
    int openCount = 0;

    if (state is TournamentListLoaded) {
      final loaded = state as TournamentListLoaded;
      totalCount = loaded.openTournaments.length + loaded.upcomingTournaments.length;
      openCount = loaded.totalOpenCount;
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primary,
            Color.lerp(primary, AppColors.primaryDark, 0.35) ?? primary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          // Background orb decoration
          Positioned(
            top: -44,
            right: -24,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: onPrimary.withValues(alpha: 0.08),
              ),
            ),
          ),
          // Background icon
          Positioned(
            top: 72,
            right: 32,
            child: Icon(
              AppIcons.tournament,
              size: AppIcons.xxl,
              color: onPrimary.withValues(alpha: 0.18),
            ),
          ),
          // Content
          Align(
            alignment: Alignment.bottomLeft,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.xl,
                88,
                68,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cạnh tranh. Kết nối. Chiến thắng.',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: onPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Tìm sân chơi phù hợp và viết nên thành tích của bạn.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: onPrimary.withValues(alpha: 0.82),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      _HeroMetric(
                        icon: AppIcons.tournament,
                        value: '$totalCount',
                        label: 'giải đấu',
                      ),
                      const SizedBox(width: AppSpacing.lg),
                      _HeroMetric(
                        icon: AppIcons.userCheck,
                        value: '$openCount',
                        label: 'đang mở',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _HeroMetric({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final onPrimary = Theme.of(context).colorScheme.onPrimary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: AppIcons.sm, color: onPrimary.withValues(alpha: 0.8)),
        const SizedBox(width: AppSpacing.xxs),
        Text(
          value,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: onPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: AppSpacing.xxs),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: onPrimary.withValues(alpha: 0.78),
          ),
        ),
      ],
    );
  }
}
