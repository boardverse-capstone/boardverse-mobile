import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';
import '../../domain/entities/cafe_table_entity.dart';

/// Bottom sheet chọn bàn — render từ `SummaryReady.availableTables` (gap #1).
///
/// Trả về `String?` id của bàn được chọn (null = không đổi).
class TablePickerSheet extends StatelessWidget {
  final List<CafeTableEntity> tables;
  final String? initialId;

  const TablePickerSheet({
    super.key,
    required this.tables,
    this.initialId,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  Icons.table_restaurant_rounded,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Chọn bàn (${tables.length})',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemCount: tables.length,
                itemBuilder: (ctx, index) {
                  final table = tables[index];
                  final isSelected = table.id == initialId;
                  return ListTile(
                    leading: Icon(
                      isSelected
                          ? Icons.radio_button_checked_rounded
                          : Icons.radio_button_unchecked_rounded,
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outline,
                    ),
                    title: Text(
                      table.name,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      '${table.seatCount} ghế'
                      '${table.pricePerHour != null ? ' • ${(table.pricePerHour! / 1000).toStringAsFixed(0)}k/h' : ''}',
                    ),
                    onTap: () => Navigator.pop(ctx, table.id),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}