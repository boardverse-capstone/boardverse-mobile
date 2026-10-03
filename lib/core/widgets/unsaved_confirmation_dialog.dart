import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/app_spacing.dart';
import '../theme/neo_brutalism_theme.dart';

/// Confirmation dialog shown when user tries to unsave (remove) a game
/// from their saved games list.
///
/// This dialog ensures users intentionally confirm the unsave action
/// since it's a destructive operation. Saving can be done freely
/// without confirmation.
///
/// Usage:
/// ```dart
/// final confirmed = await showDialog<bool>(
///   context: context,
///   builder: (_) => UnsavedConfirmationDialog(
///     gameName: 'Catan',
///   ),
/// );
/// if (confirmed == true) {
///   // Unsaves the game
/// }
/// ```
class UnsavedConfirmationDialog extends StatelessWidget {
  /// Name of the game to be unsaved.
  final String gameName;

  /// Custom title text (optional).
  final String? title;

  /// Custom message text (optional).
  final String? message;

  /// Custom confirm button label (optional).
  final String? confirmLabel;

  /// Custom cancel button label (optional).
  final String? cancelLabel;

  const UnsavedConfirmationDialog({
    super.key,
    required this.gameName,
    this.title,
    this.message,
    this.confirmLabel,
    this.cancelLabel,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.borderDark : AppColors.border;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 340),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: borderColor,
            width: 3,
          ),
          boxShadow: NeoBrutalismTheme.lightShadow(
            shadowColor: Colors.black.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with warning icon
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(17),
                ),
              ),
              child: Column(
                children: [
                  // Warning icon container
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.error,
                        width: 2.5,
                      ),
                    ),
                    child: Icon(
                      Icons.bookmark_remove_rounded,
                      size: 28,
                      color: AppColors.error,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Title
                  Text(
                    title ?? 'Bỏ lưu game?',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xs),

                  // Game name highlight
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xxs,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      gameName,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.accent,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            // Body
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: Column(
                children: [
                  // Message
                  Text(
                    message ??
                        'Bạn có chắc muốn bỏ lưu game này?\nGame sẽ không còn xuất hiện trong danh sách yêu thích của bạn.',
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Buttons row
                  Row(
                    children: [
                      // Cancel button
                      Expanded(
                        child: _DialogButton(
                          label: cancelLabel ?? 'HỦY',
                          icon: Icons.close_rounded,
                          backgroundColor: isDark
                              ? AppColors.surfaceContainerDark
                              : AppColors.surfaceVariant,
                          textColor: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimary,
                          borderColor: borderColor,
                          onPressed: () => Navigator.of(context).pop(false),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),

                      // Confirm button (danger)
                      Expanded(
                        child: _DialogButton(
                          label: confirmLabel ?? 'BỎ LƯU',
                          icon: Icons.bookmark_remove_rounded,
                          backgroundColor: AppColors.error,
                          textColor: AppColors.white,
                          borderColor: borderColor,
                          onPressed: () => Navigator.of(context).pop(true),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Neo-Brutalist dialog button.
class _DialogButton extends StatelessWidget {
  const _DialogButton({
    required this.label,
    required this.icon,
    required this.backgroundColor,
    required this.textColor,
    required this.borderColor,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final Color backgroundColor;
  final Color textColor;
  final Color borderColor;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.sm + 2,
          ),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: borderColor,
              width: 2,
            ),
            boxShadow: NeoBrutalismTheme.lightShadow(
              shadowColor: Colors.black.withValues(alpha: 0.15),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: AppIcons.sm, color: textColor),
              const SizedBox(width: AppSpacing.xxs),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
