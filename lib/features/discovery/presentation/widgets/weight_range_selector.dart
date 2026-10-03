import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

/// Widget chọn weight range — single-select chips 1-5.
///
/// Hiển thị 5 chip cho Light → Heavy. Chỉ cho phép chọn 1 ô tại một
/// thời điểm — bấm vào chip khác sẽ thay thế lựa chọn hiện tại, bấm
/// vào chip đang chọn sẽ bỏ chọn.
class WeightRangeSelector extends StatelessWidget {
  final List<int> selectedValues; // Backend enum values: 1-5
  final ValueChanged<List<int>> onChanged;

  const WeightRangeSelector({
    super.key,
    required this.selectedValues,
    required this.onChanged,
  });

  static const _options = [
    (value: 1, label: 'Nhẹ', range: '1.0–1.99'),
    (value: 2, label: 'Trung bình Nhẹ', range: '2.0–2.99'),
    (value: 3, label: 'Trung bình', range: '3.0–3.49'),
    (value: 4, label: 'Trung bình Nặng', range: '3.5–3.99'),
    (value: 5, label: 'Nặng', range: '4.0+'),
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: _options.map((opt) {
        final isSelected = selectedValues.contains(opt.value);
        return _WeightChip(
          label: opt.label,
          range: opt.range,
          isSelected: isSelected,
          onTap: () {
            // Single-select: bấm lại chip đang chọn sẽ bỏ chọn,
            // bấm chip khác sẽ thay thế lựa chọn cũ.
            if (isSelected) {
              onChanged(const <int>[]);
            } else {
              onChanged(<int>[opt.value]);
            }
          },
        );
      }).toList(),
    );
  }
}

class _WeightChip extends StatelessWidget {
  final String label;
  final String range;
  final bool isSelected;
  final VoidCallback onTap;

  const _WeightChip({
    required this.label,
    required this.range,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.12)
              : (isDark ? AppColors.surfaceDark : AppColors.surface),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : (isDark ? AppColors.borderDark : AppColors.border),
            width: isSelected ? 2 : 1.5,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
                color: isSelected
                    ? AppColors.primary
                    : (isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimary),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              range,
              style: TextStyle(
                fontSize: 11,
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.8)
                    : (isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
