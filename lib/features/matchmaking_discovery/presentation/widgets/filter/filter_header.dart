import 'package:flutter/material.dart';

import '../../../../../core/theme/app_spacing.dart';

/// Header cho FilterBottomSheet — drag handle + title + Reset button.
class FilterHeader extends StatelessWidget {
  final VoidCallback onReset;

  const FilterHeader({super.key, required this.onReset});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        // Drag handle
        Container(
          margin: const EdgeInsets.only(top: AppSpacing.xs),
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: theme.colorScheme.outlineVariant,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.xs,
            AppSpacing.xs,
          ),
          child: Row(
            children: [
              const Icon(Icons.tune, size: AppSpacing.lg),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  'Bộ lọc',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: onReset,
                icon: const Icon(Icons.refresh, size: AppSpacing.md),
                label: const Text('Đặt lại'),
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.error,
                ),
              ),
            ],
          ),
        ),
        Divider(
          height: 1,
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ],
    );
  }
}