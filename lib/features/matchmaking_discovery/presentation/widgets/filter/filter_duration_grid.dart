import 'package:flutter/material.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../domain/entities/search_filter_entity.dart';
import 'filter_duration_row.dart';

class FilterDurationGrid extends StatelessWidget {
  final Set<DurationRange> selected;
  final ValueChanged<DurationRange> onToggle;

  const FilterDurationGrid({
    super.key,
    required this.selected,
    required this.onToggle,
  });

  static const _items = <(DurationRange, IconData, String)>[
    (DurationRange.under30, Icons.bolt, '< 30 phút'),
    (DurationRange.thirtyToSixty, Icons.schedule, '30-60 phút'),
    (DurationRange.over60, Icons.hourglass_bottom, '> 60 phút'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final (range, icon, label) in _items)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: FilterDurationRow(
              icon: icon,
              label: label,
              selected: selected.contains(range),
              onTap: () => onToggle(range),
            ),
          ),
      ],
    );
  }
}