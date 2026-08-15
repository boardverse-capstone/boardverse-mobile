import 'package:flutter/material.dart';

import 'package:boardverse/core/theme/app_colors.dart';
import 'package:boardverse/core/theme/app_spacing.dart';
import 'package:boardverse/core/theme/neo_brutalism_theme.dart';

/// Empty state theo Neo-Brutalism — icon trong brutal box primary tinted +
/// title + message. Dùng khi leaderboard list trống.
class LeaderboardEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const LeaderboardEmptyState({
    super.key,
    this.icon = Icons.emoji_events_outlined,
    this.title = 'Chưa có bảng xếp hạng',
    this.message = 'Bảng xếp hạng sẽ cập nhật khi có dữ liệu từ hệ thống.',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: NeoBrutalismTheme.autoBox(
                context,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                borderColor: AppColors.primary,
                borderRadius: 20,
              ),
              child: Icon(
                icon,
                size: 48,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Error state với retry button theo Neo-Brutalism.
class LeaderboardErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const LeaderboardErrorState({
    super.key,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: NeoBrutalismTheme.autoBox(
                context,
                backgroundColor: AppColors.error.withValues(alpha: 0.1),
                borderColor: AppColors.error,
                borderRadius: 20,
              ),
              child: Icon(
                Icons.error_outline,
                size: 48,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Đã xảy ra lỗi',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            _RetryButton(onRetry: onRetry),
          ],
        ),
      ),
    );
  }
}

class _RetryButton extends StatefulWidget {
  final VoidCallback onRetry;
  const _RetryButton({required this.onRetry});

  @override
  State<_RetryButton> createState() => _RetryButtonState();
}

class _RetryButtonState extends State<_RetryButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onRetry,
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 80),
        curve: Curves.easeOut,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          decoration: NeoBrutalismTheme.brutalBox(
            backgroundColor: AppColors.primary,
            borderColor: AppColors.border,
            shadowColor: Colors.black.withValues(alpha: 0.4),
            borderRadius: 12,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.refresh, color: AppColors.white, size: 18),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'THỬ LẠI',
                style: const TextStyle(
                  color: AppColors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
