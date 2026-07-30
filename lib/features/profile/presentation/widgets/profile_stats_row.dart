import 'package:flutter/material.dart';

import 'package:boardverse_mobile/core/theme/app_icons.dart';
import 'package:boardverse_mobile/core/theme/app_spacing.dart';
import 'package:boardverse_mobile/features/profile/domain/entities/profile_entity.dart';
import 'package:boardverse_mobile/features/profile/presentation/widgets/stat_card.dart';

/// Row hiển thị 3 chỉ số quan trọng của profile: ELO rating, Level, Karma.
///
/// Layout responsive:
/// - width >= 600 → 3 cột.
/// - width <  600 → 1 cột (mobile).
///
/// Dùng [LayoutBuilder] để tránh overflow trên màn hình nhỏ.
class ProfileStatsRow extends StatelessWidget {
  const ProfileStatsRow({required this.profile, super.key});

  final ProfileEntity profile;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 600;
        final cards = [
          _eloCard(context),
          _levelCard(context),
          _karmaCard(context),
        ];

        if (isWide) {
          return Row(
            children: [
              for (var i = 0; i < cards.length; i++) ...[
                if (i > 0) const SizedBox(width: AppSpacing.md),
                Expanded(child: cards[i]),
              ],
            ],
          );
        }

        return Column(
          children: [
            for (var i = 0; i < cards.length; i++) ...[
              if (i > 0) const SizedBox(height: AppSpacing.sm),
              cards[i],
            ],
          ],
        );
      },
    );
  }

  Widget _eloCard(BuildContext context) => ProfileStatCard(
        label: 'ELO RATING',
        value: '${profile.globalElo}',
        icon: Icons.emoji_events_outlined,
        accentColor: Theme.of(context).colorScheme.tertiary,
      );

  Widget _levelCard(BuildContext context) => ProfileStatCard(
        label: 'LEVEL / CẤP ĐỘ',
        value: '${profile.level}',
        icon: AppIcons.level,
        accentColor: Theme.of(context).colorScheme.primary,
      );

  Widget _karmaCard(BuildContext context) => ProfileStatCard(
        label: 'KARMA / UY TÍN',
        value: profile.karmaPoints != null ? '${profile.karmaPoints}' : '—',
        icon: AppIcons.karma,
        accentColor: Theme.of(context).colorScheme.error,
      );
}
