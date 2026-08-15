import 'package:flutter/material.dart';

import 'package:boardverse/core/theme/app_colors.dart';
import 'package:boardverse/core/theme/app_icons.dart';
import 'package:boardverse/core/theme/neo_brutalism_theme.dart';
import 'package:boardverse/features/tournament/presentation/cubit/tournament_list_state.dart';

/// Neo-brutalism Hero header cho tab Tournament — gradient background với
/// pattern trang trí.
class TournamentHero extends StatelessWidget {
  final TournamentListState state;

  const TournamentHero({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.borderDark : AppColors.border;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.secondary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border(
          bottom: BorderSide(
            color: borderColor,
            width: NeoBrutalismTheme.borderWidthBold,
          ),
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -44,
            right: -24,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.white.withValues(alpha: 0.12),
                border: Border.all(
                  color: AppColors.white.withValues(alpha: 0.3),
                  width: 3,
                ),
              ),
            ),
          ),
          Positioned(
            top: 72,
            right: 32,
            child: Icon(
              AppIcons.tournament,
              size: AppIcons.xxl,
              color: AppColors.white.withValues(alpha: 0.25),
            ),
          ),
        ],
      ),
    );
  }
}