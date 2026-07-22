import 'package:flutter/material.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/friend_entity.dart';

/// Card hiển thị kết quả tìm kiếm user.
class UserSearchCard extends StatelessWidget {
  const UserSearchCard({
    super.key,
    required this.user,
    this.onSendRequest,
  });

  final UserSearchEntity user;
  final VoidCallback? onSendRequest;

  String get _initials {
    if (user.username.isEmpty) return '?';
    return user.username.substring(0, 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasImage =
        user.avatarUrl.isNotEmpty && user.avatarUrl.startsWith('http');

    Widget? actionWidget;
    switch (user.friendshipStatus) {
      case FriendshipStatus.none:
        actionWidget = FilledButton.icon(
          onPressed: onSendRequest,
          icon: const Icon(Icons.person_add_alt_1_outlined, size: 16),
          label: const Text('Kết bạn'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12),
          ),
        );
        break;
      case FriendshipStatus.pendingSent:
        actionWidget = OutlinedButton.icon(
          onPressed: null,
          icon: const Icon(Icons.schedule, size: 16),
          label: const Text('Đã gửi'),
        );
        break;
      case FriendshipStatus.pendingReceived:
        actionWidget = OutlinedButton.icon(
          onPressed: null,
          icon: const Icon(Icons.inbox_outlined, size: 16),
          label: const Text('Chờ bạn chấp nhận'),
        );
        break;
      case FriendshipStatus.accepted:
        actionWidget = OutlinedButton.icon(
          onPressed: null,
          icon: const Icon(Icons.check_circle_outline, size: 16),
          label: const Text('Bạn bè'),
        );
        break;
      case FriendshipStatus.blocked:
        actionWidget = OutlinedButton.icon(
          onPressed: null,
          icon: const Icon(Icons.block, size: 16),
          label: const Text('Đã chặn'),
        );
        break;
      case null:
        actionWidget = FilledButton.icon(
          onPressed: onSendRequest,
          icon: const Icon(Icons.person_add_alt_1_outlined, size: 16),
          label: const Text('Kết bạn'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12),
          ),
        );
        break;
    }

    return Material(
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
        borderRadius: BorderRadius.circular(AppRadius.radiusMd),
      ),
      borderRadius: BorderRadius.circular(AppRadius.radiusMd),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: theme.colorScheme.primaryContainer,
              backgroundImage:
                  hasImage ? NetworkImage(user.avatarUrl) : null,
              onBackgroundImageError: hasImage ? (_, _) {} : null,
              child: hasImage
                  ? null
                  : Text(
                      _initials,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.username,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        Icons.local_fire_department_outlined,
                        size: 14,
                        color: Colors.orange.shade400,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${user.karmaPoints}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (user.mutualFriendsCount > 0) ...[
                        const SizedBox(width: AppSpacing.sm),
                        Icon(
                          Icons.people_alt_outlined,
                          size: 14,
                          color: theme.colorScheme.outline,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${user.mutualFriendsCount} bạn chung',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            actionWidget,
          ],
        ),
      ),
    );
  }
}