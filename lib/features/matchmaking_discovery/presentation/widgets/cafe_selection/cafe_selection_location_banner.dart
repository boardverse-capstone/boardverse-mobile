import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/neo_brutalism_theme.dart';

/// Neo-brutalism Banner ngắn hiển thị thông tin vị trí hiện tại.
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

  Widget _neoMiniButton({
    required Widget child,
    required VoidCallback? onPressed,
    Color? color,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: color ?? AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppColors.black,
              width: NeoBrutalismTheme.borderWidth,
            ),
          ),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.xs,
        AppSpacing.md,
        0,
      ),
      padding: AppSpacing.paddingAllSm,
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.border,
          width: NeoBrutalismTheme.borderWidth,
        ),
        boxShadow: NeoBrutalismTheme.lightShadow(
          shadowColor: AppColors.black.withValues(alpha: 0.06),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.xs),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              hasManualLocation
                  ? Icons.edit_location_alt
                  : Icons.my_location,
              color: AppColors.white,
              size: AppSpacing.lg,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              hasManualLocation
                  ? 'Đang dùng vị trí đã chọn thủ công.'
                  : 'Đang tìm quán quanh vị trí đã lưu của bạn.',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (hasManualLocation)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.xxs),
              child: _neoMiniButton(
                color: AppColors.white,
                onPressed: isUpdating ? null : onClearManualLocation,
                child: Text(
                  'Dùng vị trí đã lưu',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.black,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          _neoMiniButton(
            color: AppColors.primary,
            onPressed: isUpdating ? null : onRefreshLocation,
            child: isUpdating
                ? const SizedBox(
                    width: AppSpacing.sm + 2,
                    height: AppSpacing.sm + 2,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.white,
                      ),
                    ),
                  )
                : Text(
                    'Cập nhật',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
