import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/neo_brutalism_theme.dart';
import '../../../domain/entities/search_filter_entity.dart';

/// Neo-brutalism Active filter chips - dễ thấy và dễ xoá.
class ActiveFilterBar extends StatelessWidget {
  final String? selectedCategory;
  final int? minPlayers;
  final Set<DurationRange> selectedDurationRanges;
  final VoidCallback onRemoveCategory;
  final VoidCallback onRemovePlayerCount;
  final void Function(DurationRange range) onRemoveDuration;

  const ActiveFilterBar({
    super.key,
    required this.selectedCategory,
    required this.minPlayers,
    required this.selectedDurationRanges,
    required this.onRemoveCategory,
    required this.onRemovePlayerCount,
    required this.onRemoveDuration,
  });

  String _durationLabel(DurationRange range) {
    switch (range) {
      case DurationRange.under30:
        return '< 30 phút';
      case DurationRange.thirtyToSixty:
        return '30-60 phút';
      case DurationRange.over60:
        return '> 60 phút';
    }
  }

  Widget _neoFilterChip({
    required String label,
    required VoidCallback onRemove,
    Color? accentColor,
  }) {
    final color = accentColor ?? AppColors.primary;
    return Container(
      margin: const EdgeInsets.only(right: AppSpacing.xs),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color,
          width: NeoBrutalismTheme.borderWidth,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onRemove,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xxs,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                const SizedBox(width: AppSpacing.xxs),
                Icon(
                  Icons.close,
                  size: 14,
                  color: color,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppSpacing.xxxl,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: AppSpacing.paddingHorizontalMd,
        children: [
          if (selectedCategory != null)
            _neoFilterChip(
              label: selectedCategory!,
              onRemove: onRemoveCategory,
            ),
          if (minPlayers != null)
            _neoFilterChip(
              label: '$minPlayers+ người',
              onRemove: onRemovePlayerCount,
              accentColor: AppColors.secondary,
            ),
          for (final range in selectedDurationRanges)
            _neoFilterChip(
              label: _durationLabel(range),
              onRemove: () => onRemoveDuration(range),
              accentColor: AppColors.accent,
            ),
        ],
      ),
    );
  }
}
