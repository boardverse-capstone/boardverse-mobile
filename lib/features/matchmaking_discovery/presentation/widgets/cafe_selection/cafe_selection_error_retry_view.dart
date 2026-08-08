import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/neo_brutalism_theme.dart';

/// Neo-brutalism Error + retry + cập nhật vị trí view dùng trong LobbyCafeSelectionPage.
class CafeSelectionErrorRetryView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final Future<void> Function() onUpdateLocation;

  const CafeSelectionErrorRetryView({
    super.key,
    required this.message,
    required this.onRetry,
    required this.onUpdateLocation,
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
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 18, color: textColor),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  label,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 13,
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
                Icons.cloud_off,
                size: AppSpacing.huge,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
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
            _neoButton(
              label: 'THỬ LẠI',
              icon: Icons.refresh,
              bgColor: AppColors.primary,
              textColor: AppColors.white,
              onPressed: onRetry,
            ),
            const SizedBox(height: AppSpacing.sm),
            _neoButton(
              label: 'CẬP NHẬT VỊ TRÍ',
              icon: Icons.my_location,
              bgColor: isDark ? AppColors.surfaceDark : AppColors.surface,
              textColor: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimary,
              borderColor: isDark ? AppColors.borderDark : AppColors.border,
              onPressed: () => onUpdateLocation(),
            ),
          ],
        ),
      ),
    );
  }
}
