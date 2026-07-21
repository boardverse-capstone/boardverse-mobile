import 'package:flutter/material.dart';

import 'package:boardverse_mobile/core/theme/theme.dart';

class TournamentFilterSection extends StatelessWidget {
  final int selectedFilter;
  final ValueChanged<int> onFilterChanged;

  const TournamentFilterSection({
    super.key,
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  static const _filterLabels = <String>[
    'Tất cả',
    'Đang mở',
    'Sắp diễn ra',
    'Đang diễn ra',
    'Đã kết thúc',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      color: theme.colorScheme.surface,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Khám phá giải đấu',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(_filterLabels.length, (index) {
                final isSelected = selectedFilter == index;
                return Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.xs),
                  child: ChoiceChip(
                    label: Text(_filterLabels[index]),
                    selected: isSelected,
                    onSelected: (_) => onFilterChanged(index),
                    showCheckmark: false,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs,
                      vertical: AppSpacing.xxs,
                    ),
                    side: BorderSide(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outlineVariant,
                    ),
                    backgroundColor: theme.colorScheme.surface,
                    selectedColor: theme.colorScheme.primaryContainer,
                    labelStyle: theme.textTheme.labelMedium?.copyWith(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.chipRadius,
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
