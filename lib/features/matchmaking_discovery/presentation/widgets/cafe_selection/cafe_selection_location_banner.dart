import 'package:flutter/material.dart';

import '../../../../../core/theme/app_spacing.dart';

/// Banner ngắn hiển thị thông tin vị trí hiện tại + nút cập nhật.
class CafeSelectionLocationBanner extends StatelessWidget {
  final bool hasManualLocation;
  final bool isUpdating;
  final VoidCallback onRefreshLocation;
  final VoidCallback onClearManualLocation;

  const CafeSelectionLocationBanner({
    super.key,
    required this.hasManualLocation,
    required this.isUpdating,
    required this.onRefreshLocation,
    required this.onClearManualLocation,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.xs,
        AppSpacing.md,
        0,
      ),
      padding: AppSpacing.paddingAllSm,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppSpacing.sm - 2),
      ),
      child: Row(
        children: [
          Icon(
            hasManualLocation ? Icons.edit_location_alt : Icons.my_location,
            color: theme.colorScheme.primary,
            size: AppSpacing.lg,
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              hasManualLocation
                  ? 'Đang dùng vị trí đã chọn thủ công.'
                  : 'Đang tìm quán quanh vị trí đã lưu của bạn.',
              style: theme.textTheme.bodySmall,
            ),
          ),
          if (hasManualLocation)
            TextButton(
              onPressed: isUpdating ? null : onClearManualLocation,
              child: const Text('Dùng vị trí đã lưu'),
            ),
          const SizedBox(width: AppSpacing.xxs),
          FilledButton.tonal(
            onPressed: isUpdating ? null : onRefreshLocation,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs - 2,
              ),
              visualDensity: VisualDensity.compact,
              textStyle: theme.textTheme.labelMedium,
            ),
            child: isUpdating
                ? const SizedBox(
                    width: AppSpacing.sm + 2,
                    height: AppSpacing.sm + 2,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Cập nhật'),
          ),
        ],
      ),
    );
  }
}