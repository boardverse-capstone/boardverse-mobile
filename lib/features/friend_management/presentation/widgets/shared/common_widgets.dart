import 'package:flutter/material.dart';

import '../../../../../core/theme/app_icons.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';

/// Avatar dùng chung cho mọi user/friend trong feature friend_management.
///
/// Hiển thị network image nếu URL hợp lệ (`http(s)://...`), ngược lại hiển
/// thị chữ cái đầu của username làm fallback. Bỏ qua lỗi load network image
/// một cách im lặng (giao diện vẫn hiển thị avatar fallback).
///
/// Dùng cho: FriendCard, FriendRequestCard, UserSearchCard, _SentRequestTile.
class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.username,
    required this.avatarUrl,
    this.radius = 24,
  });

  final String username;
  final String avatarUrl;
  final double radius;

  String get _initials {
    if (username.isEmpty) return '?';
    return username.substring(0, 1).toUpperCase();
  }

  bool get _hasImage =>
      avatarUrl.isNotEmpty && avatarUrl.startsWith('http');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return CircleAvatar(
      radius: radius,
      backgroundColor: theme.colorScheme.primaryContainer,
      backgroundImage: _hasImage ? NetworkImage(avatarUrl) : null,
      onBackgroundImageError: _hasImage ? (_, _) {} : null,
      child: _hasImage
          ? null
          : Text(
              _initials,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
    );
  }
}

/// Avatar có viền màu (dùng cho friend card hiển thị gamer tier).
class TieredAvatar extends StatelessWidget {
  const TieredAvatar({
    super.key,
    required this.username,
    required this.avatarUrl,
    required this.borderColor,
    this.radius = 26,
    this.borderWidth = 2,
  });

  final String username;
  final String avatarUrl;
  final Color borderColor;
  final double radius;
  final double borderWidth;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: borderWidth),
      ),
      child: UserAvatar(
        username: username,
        avatarUrl: avatarUrl,
        radius: radius,
      ),
    );
  }
}

/// Pattern "card" có viền outline mờ — dùng cho FriendCard, FriendRequestCard,
/// UserSearchCard. Tránh lặp BorderSide + RoundedRectangleBorder.
class OutlinedCard extends StatelessWidget {
  const OutlinedCard({
    super.key,
    required this.child,
    this.borderColor,
    this.borderWidth = 1,
    this.radius = AppRadius.radiusMd,
    this.onTap,
    this.clipBehavior = Clip.antiAlias,
  });

  final Widget child;
  final Color? borderColor;
  final double borderWidth;
  final double radius;
  final VoidCallback? onTap;
  final Clip clipBehavior;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveBorderColor =
        borderColor ?? theme.colorScheme.outlineVariant.withValues(alpha: 0.6);
    return Material(
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: effectiveBorderColor, width: borderWidth),
        borderRadius: BorderRadius.circular(radius),
      ),
      clipBehavior: clipBehavior,
      child: onTap == null
          ? child
          : InkWell(onTap: onTap, child: child),
    );
  }
}

/// Empty state — icon tròn + title + subtitle. Dùng cho mọi tab khi list rỗng.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

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
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 48,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Error state — icon + message + retry button. Dùng cho mọi tab khi load fail.
class ErrorRetryView extends StatelessWidget {
  const ErrorRetryView({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(AppIcons.refresh),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Section title + optional badge count. Dùng cho phần header của mỗi section
/// trong tab lời mời.
class SectionTitle extends StatelessWidget {
  const SectionTitle({super.key, required this.title, this.count});

  final String title;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      child: Row(
        children: [
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          if (count != null) ...[
            const SizedBox(width: AppSpacing.xs),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
