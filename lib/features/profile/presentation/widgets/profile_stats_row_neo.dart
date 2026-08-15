import 'package:flutter/material.dart';

import 'package:boardverse/core/theme/app_icons.dart';
import 'package:boardverse/core/theme/app_spacing.dart';
import 'package:boardverse/core/theme/app_colors.dart';
import 'package:boardverse/features/profile/domain/entities/profile_entity.dart';
import 'package:boardverse/features/profile/presentation/widgets/profile_stat_card_neo.dart';

/// Neo-brutalism Profile Stats - BIG CARDS
///
/// Gồm 3 cards xếp theo layout:
/// - Hàng trên: ELO Rating (1 card to)
/// - Hàng dưới: Level + Karma (2 cards ngang)
class ProfileStatsRowNeoCompact extends StatelessWidget {
  const ProfileStatsRowNeoCompact({required this.profile, super.key});

  final ProfileEntity profile;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ELO Card - CAM (Primary)
        ProfileStatCardNeo(
          label: 'ELO RATING',
          value: '${profile.globalElo}',
          icon: Icons.emoji_events_rounded,
          accentColor: AppColors.primary,
        ),
        const SizedBox(height: AppSpacing.sm),

        // Level + Karma - 2 cards ngang
        Row(
          children: [
            Expanded(
              child: ProfileStatCardNeo(
                label: 'LEVEL',
                value: '${profile.level}',
                icon: AppIcons.level,
                accentColor: AppColors.secondary,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: ProfileStatCardNeo(
                label: 'KARMA',
                value: profile.karmaPoints != null ? '${profile.karmaPoints}' : '—',
                icon: AppIcons.karma,
                accentColor: AppColors.success,
              ),
            ),
          ],
        ),
      ],
    );
  }
}