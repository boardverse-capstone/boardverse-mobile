import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/neo_brutalism_theme.dart';

/// Common "error with retry" empty state — Neo-brutalism style.
/// Used in board game detail page.
///
/// Khi [requiresLocationUpdate] = true, hiển thị button "CẬP NHẬT VỊ TRÍ"
/// (primary) + button "THỬ LẠI" (secondary). Ngược lại chỉ hiển thị
/// button "THỬ LẠI".
class BoardGameDetailErrorRetryView extends StatelessWidget {
  /// Message lỗi đã được sanitize (thân thiện với user).
  final String message;

  /// Callback khi player bấm "THỬ LẠI" — re-fetch game detail.
  final VoidCallback onRetry;

  /// Callback khi player bấm "CẬP NHẬT VỊ TRÍ". Bắt buộc.
  final Future<void> Function() onUpdateLocation;

  /// `true` khi lỗi do player chưa cập nhật vị trí (backend 400 +
  /// message chứa keyword location). UI sẽ:
  /// - Đổi tiêu đề thành "Chưa có vị trí hiện tại"
  /// - Đổi icon thành `Icons.location_off_rounded`
  /// - Style button "CẬP NHẬT VỊ TRÍ" thành primary (nổi bật hơn
  ///   button "THỬ LẠI")
  final bool requiresLocationUpdate;

  const BoardGameDetailErrorRetryView({
    super.key,
    required this.message,
    required this.onRetry,
    required this.onUpdateLocation,
    this.requiresLocationUpdate = false,
  });

  Widget _neoButton({
    required String label,
    required IconData icon,
    required Color bgColor,
    required Color textColor,
    Color? borderColor,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: borderColor ?? bgColor,
          width: NeoBrutalismTheme.borderWidth,
        ),
        boxShadow: NeoBrutalismTheme.lightShadow(
          shadowColor: bgColor.withValues(alpha: 0.4),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
              vertical: AppSpacing.md,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 18, color: textColor),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  label,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final title = requiresLocationUpdate
        ? 'Chưa có vị trí hiện tại'
        : 'Không thể tải thông tin game';
    final iconData = requiresLocationUpdate
        ? Icons.location_off_rounded
        : Icons.error_outline;

    final primaryButton = requiresLocationUpdate
        ? _neoButton(
            label: 'CẬP NHẬT VỊ TRÍ',
            icon: Icons.my_location_rounded,
            bgColor: AppColors.primary,
            textColor: AppColors.white,
            onPressed: () => onUpdateLocation(),
          )
        : _neoButton(
            label: 'THỬ LẠI',
            icon: Icons.refresh_rounded,
            bgColor: AppColors.primary,
            textColor: AppColors.white,
            onPressed: onRetry,
          );

    final secondaryButton = _neoButton(
      label: 'THỬ LẠI',
      icon: Icons.refresh_rounded,
      bgColor: isDark ? AppColors.surfaceDark : AppColors.surface,
      textColor:
          isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
      borderColor: isDark ? AppColors.borderDark : AppColors.border,
      onPressed: onRetry,
    );

    return Center(
      child: Padding(
        padding: AppSpacing.paddingAllXl,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.error,
                  width: NeoBrutalismTheme.borderWidth,
                ),
                boxShadow: NeoBrutalismTheme.lightShadow(
                  shadowColor: AppColors.error.withValues(alpha: 0.3),
                ),
              ),
              child: Icon(
                iconData,
                size: AppSpacing.huge,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Primary button
            primaryButton,

            // Secondary button (chỉ khi location-required)
            if (requiresLocationUpdate) ...[
              const SizedBox(height: AppSpacing.sm),
              secondaryButton,
            ],
          ],
        ),
      ),
    );
  }
}