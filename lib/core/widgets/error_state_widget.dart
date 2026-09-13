import 'package:flutter/material.dart';

import 'package:boardverse/core/theme/app_colors.dart';
import 'package:boardverse/core/theme/app_icons.dart';
import 'package:boardverse/core/theme/app_spacing.dart';
import 'package:boardverse/core/theme/neo_brutalism_theme.dart';

/// Shared Error State widget following Neo-Brutalism design pattern.
/// 
/// Use this widget when an error occurs while loading data.
/// The widget displays:
/// - An error icon in a neo-brutalism circle
/// - A title ("Đã xảy ra lỗi")
/// - The error message
/// - A retry button
/// 
/// Usage:
/// ```dart
/// return ErrorStateWidget(
///   message: 'Không thể tải dữ liệu. Vui lòng thử lại.',
///   onRetry: () => loadData(),
/// );
/// 
/// // With custom title
/// return ErrorStateWidget(
///   message: 'Network timeout',
///   title: 'Mất kết nối',
///   onRetry: () => loadData(),
/// );
/// ```
class ErrorStateWidget extends StatelessWidget {
  /// Error message to display
  final String message;

  /// Custom title (default: "Đã xảy ra lỗi")
  final String? title;

  /// Callback when retry button is pressed
  final VoidCallback onRetry;

  /// Custom retry button label (default: "THỬ LẠI")
  final String? retryLabel;

  /// Custom icon (default: `Icons.error_outline`)
  final IconData? icon;

  /// Use compact layout (less vertical spacing)
  final bool compact;

  /// Whether to show the retry button
  final bool showRetry;

  const ErrorStateWidget({
    super.key,
    required this.message,
    this.title,
    required this.onRetry,
    this.retryLabel,
    this.icon,
    this.compact = false,
    this.showRetry = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.borderDark : AppColors.border;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(compact ? AppSpacing.lg : AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Error icon - Neo-Brutalism circle
            Container(
              padding: EdgeInsets.all(compact ? AppSpacing.md : AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.error,
                  width: NeoBrutalismTheme.borderWidthBold,
                ),
                boxShadow: NeoBrutalismTheme.lightShadow(
                  shadowColor: AppColors.error.withValues(alpha: 0.4),
                ),
              ),
              child: Icon(
                icon ?? Icons.error_outline,
                size: compact ? AppIcons.xl : AppIcons.xxl,
                color: AppColors.error,
              ),
            ),
            SizedBox(height: compact ? AppSpacing.md : AppSpacing.lg),

            // Title
            Text(
              (title ?? 'Đã xảy ra lỗi').toUpperCase(),
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: 0.8,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              ),
            ),
            SizedBox(height: AppSpacing.xs),

            // Error message
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 300),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
            ),

            // Retry button
            if (showRetry) ...[
              SizedBox(height: compact ? AppSpacing.md : AppSpacing.lg),
              _RetryButton(
                label: retryLabel ?? 'THỬ LẠI',
                icon: AppIcons.refresh,
                onPressed: onRetry,
                borderColor: borderColor,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Neo-Brutalism retry button.
class _RetryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final Color borderColor;

  const _RetryButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: borderColor,
              width: NeoBrutalismTheme.borderWidthBold,
            ),
            boxShadow: NeoBrutalismTheme.lightShadow(
              shadowColor: AppColors.primary.withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: AppColors.white, size: AppIcons.sm),
              const SizedBox(width: AppSpacing.sm),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.white,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// PRE-BUILT ERROR STATES FOR COMMON USE CASES
// ════════════════════════════════════════════════════════════════════════════

/// Pre-configured error state for network-related errors.
class NetworkErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  final String? customMessage;

  const NetworkErrorState({
    super.key,
    required this.onRetry,
    this.customMessage,
  });

  @override
  Widget build(BuildContext context) {
    return ErrorStateWidget(
      icon: Icons.wifi_off_rounded,
      title: 'Mất kết nối',
      message: customMessage ??
          'Không thể kết nối đến máy chủ. Hãy kiểm tra kết nối internet và thử lại.',
      onRetry: onRetry,
    );
  }
}

/// Pre-configured error state for server errors.
class ServerErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  final int? statusCode;

  const ServerErrorState({
    super.key,
    required this.onRetry,
    this.statusCode,
  });

  @override
  Widget build(BuildContext context) {
    String message;
    if (statusCode != null) {
      if (statusCode == 500) {
        message = 'Máy chủ đang bận. Hãy thử lại sau trong giây lát.';
      } else if (statusCode == 503) {
        message = 'Dịch vụ tạm thời không khả dụng. Hãy thử lại sau.';
      } else if (statusCode == 404) {
        message = 'Không tìm thấy dữ liệu. Trang có thể đã bị xóa hoặc di chuyển.';
      } else if (statusCode == 401 || statusCode == 403) {
        message = 'Phiên đăng nhập hết hạn. Vui lòng đăng nhập lại.';
      } else {
        message = 'Đã xảy ra lỗi từ máy chủ (Mã lỗi: $statusCode).';
      }
    } else {
      message = 'Đã xảy ra lỗi không mong đợi. Hãy thử lại.';
    }

    return ErrorStateWidget(
      icon: Icons.cloud_off_rounded,
      message: message,
      onRetry: onRetry,
    );
  }
}

/// Pre-configured error state for authentication errors.
class AuthErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  final VoidCallback? onLogin;

  const AuthErrorState({
    super.key,
    required this.onRetry,
    this.onLogin,
  });

  @override
  Widget build(BuildContext context) {
    return ErrorStateWidget(
      icon: Icons.lock_outline,
      title: 'Xác thực thất bại',
      message: 'Phiên đăng nhập đã hết hạn hoặc bạn không có quyền truy cập.',
      onRetry: onRetry,
      retryLabel: onLogin != null ? 'ĐĂNG NHẬP LẠI' : 'THỬ LẠI',
      showRetry: onLogin == null,
    );
  }
}

/// Pre-configured error state for loading data errors.
class DataLoadErrorState extends StatelessWidget {
  final String dataType;
  final VoidCallback onRetry;

  const DataLoadErrorState({
    super.key,
    required this.dataType,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return ErrorStateWidget(
      icon: Icons.sync_problem_rounded,
      message: 'Không thể tải $dataType. Hãy thử lại để tiếp tục.',
      onRetry: onRetry,
    );
  }
}

/// Pre-configured error state for permission denied errors.
class PermissionErrorState extends StatelessWidget {
  final String permission;
  final VoidCallback onRequestPermission;
  final VoidCallback? onOpenSettings;

  const PermissionErrorState({
    super.key,
    required this.permission,
    required this.onRequestPermission,
    this.onOpenSettings,
  });

  @override
  Widget build(BuildContext context) {
    return ErrorStateWidget(
      icon: Icons.block_rounded,
      title: 'Không có quyền truy cập',
      message:
          'Ứng dụng cần quyền "$permission" để hoạt động. Hãy cấp quyền trong Cài đặt.',
      onRetry: onRequestPermission,
      retryLabel: 'CẤP QUYỀN',
      showRetry: true,
    );
  }
}

/// Compact inline error banner - for use within lists or cards.
/// Unlike ErrorStateWidget which is full-screen, this is a small inline widget.
class ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final VoidCallback? onDismiss;

  const ErrorBanner({
    super.key,
    required this.message,
    this.onRetry,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.error.withValues(alpha: 0.15)
            : colors.errorContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.error.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: AppColors.error,
            size: AppIcons.md,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(width: AppSpacing.xs),
            InkWell(
              onTap: onRetry,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xxs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Thử lại',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
          if (onDismiss != null) ...[
            const SizedBox(width: AppSpacing.xs),
            IconButton(
              icon: const Icon(Icons.close, size: AppIcons.sm),
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
              onPressed: onDismiss,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 24,
                minHeight: 24,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
