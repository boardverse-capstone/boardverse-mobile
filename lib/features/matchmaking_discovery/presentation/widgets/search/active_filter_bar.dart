import 'package:flutter/material.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../domain/entities/search_filter_entity.dart';

/// Thanh chip filter đang active — dễ thấy và dễ xoá.
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

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppSpacing.xxxl,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: AppSpacing.paddingHorizontalMd,
        children: [
          if (selectedCategory != null)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.xs),
              child: InputChip(
                label: Text(selectedCategory!),
                onDeleted: onRemoveCategory,
              ),
            ),
          if (minPlayers != null)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.xs),
              child: InputChip(
                label: Text('$minPlayers+ người'),
                onDeleted: onRemovePlayerCount,
              ),
            ),
          for (final range in selectedDurationRanges)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.xs),
              child: InputChip(
                label: Text(_durationLabel(range)),
                onDeleted: () => onRemoveDuration(range),
              ),
            ),
        ],
      ),
    );
  }
}