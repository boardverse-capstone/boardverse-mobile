import 'package:flutter/material.dart';

import 'package:boardverse_mobile/core/theme/app_icons.dart';
import 'package:boardverse_mobile/core/theme/app_spacing.dart';
import 'package:boardverse_mobile/core/theme/app_colors.dart';
import 'package:boardverse_mobile/features/profile/domain/entities/profile_entity.dart';
import 'package:boardverse_mobile/features/profile/presentation/widgets/profile_stat_card_neo.dart';

/// Neo-brutalism Profile Stats - BIG CARDS
/// 
/// Features:
/// - 3 cards xếp dọc, mỗi card TO
/// - Hiển thị đầy đủ thông tin (ELO, Level, Karma)
/// - Brand colors cho từng stat
/// - Dễ nhìn, dễ đọc trên mobile
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
          subtitle: _getEloTitle(profile.globalElo),
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
                subtitle: _getLevelTitle(profile.level),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: ProfileStatCardNeo(
                label: 'KARMA',
                value: profile.karmaPoints != null ? '${profile.karmaPoints}' : '—',
                icon: AppIcons.karma,
                accentColor: AppColors.success,
                subtitle: _getKarmaTitle(profile.karmaPoints),
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _getEloTitle(int elo) {
    if (elo >= 2000) return '⚔️ Master';
    if (elo >= 1800) return '🏆 Diamond';
    if (elo >= 1600) return '💎 Platinum';
    if (elo >= 1400) return '🥇 Gold';
    if (elo >= 1200) return '🥈 Silver';
    return '🥉 Bronze';
  }

  String _getLevelTitle(int level) {
    if (level >= 50) return '🎖️ Veteran';
    if (level >= 40) return '⭐ Expert';
    if (level >= 30) return '🌟 Advanced';
    if (level >= 20) return '📈 Intermediate';
    if (level >= 10) return '🔰 Beginner';
    return '🆕 Newbie';
  }

  String _getKarmaTitle(int? karma) {
    if (karma == null) return 'Chưa có';
    if (karma >= 5000) return '✨ Legend';
    if (karma >= 2500) return '🌟 Hero';
    if (karma >= 1000) return '👍 Good';
    if (karma >= 500) return '👤 Member';
    return '🌱 Fresh';
  }
}
