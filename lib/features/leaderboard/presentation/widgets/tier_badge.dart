import 'package:flutter/material.dart';

import 'package:boardverse/core/theme/app_colors.dart';
import 'package:boardverse/core/theme/app_spacing.dart';
import 'package:boardverse/features/leaderboard/domain/entities/gamer_tier.dart';
import 'package:boardverse/features/leaderboard/presentation/widgets/gamer_tier_color.dart';

/// Tier badge theo Neo-Brutalism — pill đậm với tier accent color +
/// border + hard shadow + uppercase label.
///
/// Dùng trong leaderboard row tile + user rank strip. Tier color resolve
/// qua `gamer_tier_color.dart` extension.
class TierBadge extends StatelessWidget {
  final GamerTier tier;
  final bool compact;

  const TierBadge({
    super.key,
    required this.tier,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = tier.accentColor;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? AppSpacing.xs : AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.border,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            offset: const Offset(2, 2),
            blurRadius: 0,
          ),
        ],
      ),
      child: Text(
        tier.label.toUpperCase(),
        style: TextStyle(
          fontSize: compact ? 9 : 10,
          fontWeight: FontWeight.w900,
          color: _foreground(color),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  /// Pick foreground tương phản — tier tối (master/grandmaster) dùng
  /// trắng, tier sáng dùng đen để đảm bảo accessibility.
  Color _foreground(Color bg) {
    final brightness = ThemeData.estimateBrightnessForColor(bg);
    return brightness == Brightness.dark ? AppColors.white : AppColors.black;
  }
}
