import 'package:flutter/material.dart';

import 'package:boardverse/core/theme/app_colors.dart';
import 'package:boardverse/features/leaderboard/domain/entities/gamer_tier.dart';

/// Map `GamerTier` → accent color theo Neo-Brutalism palette.
///
/// Tách ra file riêng để presentation widget dùng chung cho cả
/// tournament + navigation leaderboard page, đồng thời giữ domain
/// layer không phụ thuộc theme.
extension GamerTierColor on GamerTier {
  Color get accentColor {
    switch (this) {
      case GamerTier.bronze:
        return AppColors.tierBronze;
      case GamerTier.silver:
        return AppColors.tierSilver;
      case GamerTier.gold:
        return AppColors.tierGold;
      case GamerTier.platinum:
        return AppColors.tierPlatinum;
      case GamerTier.diamond:
        return AppColors.tierDiamond;
      case GamerTier.master:
        return AppColors.tierMaster;
      case GamerTier.grandmaster:
        return AppColors.tierGrandmaster;
      case GamerTier.unknown:
        return AppColors.textTertiary;
    }
  }
}
