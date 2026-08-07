import 'package:flutter/material.dart';

import '../../../../../core/theme/app_spacing.dart';
import 'filter_player_bubble.dart';

/// RangeSlider cho Min/Max số người chơi, có bubble preview phía trên.
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
    final theme = Theme.of(context);
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: FilterPlayerBubble(label: 'Min', value: values.start.toInt()),
            ),
            Container(
              width: AppSpacing.md,
              height: 2,
              margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              color: theme.colorScheme.outlineVariant,
            ),
            Expanded(
              child: FilterPlayerBubble(label: 'Max', value: values.end.toInt()),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: theme.colorScheme.primary,
            inactiveTrackColor: theme.colorScheme.primary.withValues(
              alpha: 0.18,
            ),
            thumbColor: theme.colorScheme.primary,
            overlayColor: theme.colorScheme.primary.withValues(alpha: 0.12),
            trackHeight: 4,
            rangeThumbShape: const RoundRangeSliderThumbShape(
              enabledThumbRadius: 10,
            ),
          ),
          child: RangeSlider(
            values: values,
            min: 1,
            max: 20,
            divisions: 19,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}