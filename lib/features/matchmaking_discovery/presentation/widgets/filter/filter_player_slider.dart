import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/neo_brutalism_theme.dart';
import 'filter_player_bubble.dart';

/// Neo-brutalism RangeSlider cho Min/Max số người chơi.
class FilterPlayerSlider extends StatelessWidget {
  final RangeValues values;
  final ValueChanged<RangeValues> onChanged;

  const FilterPlayerSlider({
    super.key,
    required this.values,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: FilterPlayerBubble(label: 'Min', value: values.start.toInt()),
            ),
            Container(
              width: AppSpacing.md,
              height: 3,
              margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              decoration: BoxDecoration(
                color: isDark ? AppColors.borderDark : AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: FilterPlayerBubble(label: 'Max', value: values.end.toInt()),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.border,
              width: NeoBrutalismTheme.borderWidth,
            ),
          ),
          child: SliderTheme(
            data: SliderThemeData(
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: AppColors.primary.withValues(alpha: 0.2),
              thumbColor: AppColors.primary,
              overlayColor: AppColors.primary.withValues(alpha: 0.15),
              trackHeight: 6,
              rangeThumbShape: const RoundRangeSliderThumbShape(
                enabledThumbRadius: 12,
                elevation: 0,
              ),
              rangeTrackShape: const RoundedRectRangeSliderTrackShape(),
            ),
            child: RangeSlider(
              values: values,
              min: 1,
              max: 20,
              divisions: 19,
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
