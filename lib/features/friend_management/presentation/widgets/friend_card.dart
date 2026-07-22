import 'package:flutter/material.dart';

import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/friend_entity.dart';

/// Card hiển thị 1 người bạn trong danh sách Friends.
class FriendCard extends StatelessWidget {
  const FriendCard({
    super.key,
    required this.friend,
    this.onTap,
    this.onUnfriend,
    this.onInviteToLobby,
  });

  final FriendEntity friend;
  final VoidCallback? onTap;
  final VoidCallback? onUnfriend;
  final VoidCallback? onInviteToLobby;

  String get _initials {
    if (friend.username.isEmpty) return '?';
    return friend.username.substring(0, 1).toUpperCase();
  }

  Color _activityColor(BuildContext context) {
    switch (friend.activityStatus) {
      case ActivityStatus.online:
        return Colors.green;
      case ActivityStatus.recentlyActive:
        return Colors.lightGreen;
      case ActivityStatus.away:
        return Colors.orange;
      case ActivityStatus.offline:
      case null:
        return Theme.of(context).colorScheme.outline;
    }
  }

  String _activityLabel() {
    switch (friend.activityStatus) {
      case ActivityStatus.online:
        return 'Đang online';
      case ActivityStatus.recentlyActive:
        return 'Vừa hoạt động';
      case ActivityStatus.away:
        return 'Tạm nghỉ';
      case ActivityStatus.offline:
      case null:
        return 'Ngoại tuyến';
    }
  }

  Color _tierColor(BuildContext context) {
    switch (friend.gamerTier) {
      case GamerTier.bronze:
        return const Color(0xFFCD7F32);
      case GamerTier.silver:
        return const Color(0xFFC0C0C0);
      case GamerTier.gold:
        return const Color(0xFFFFD700);
      case GamerTier.platinum:
        return const Color(0xFFB0E0E6);
      case GamerTier.diamond:
        return const Color(0xFFB9F2FF);
      case null:
        return Theme.of(context).colorScheme.outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasImage =
        friend.avatarUrl.isNotEmpty && friend.avatarUrl.startsWith('http');

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
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              // Avatar with online indicator
              Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _tierColor(context),
                        width: 2,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 26,
                      backgroundColor: theme.colorScheme.primaryContainer,
                      backgroundImage: hasImage
                          ? NetworkImage(friend.avatarUrl)
                          : null,
                      onBackgroundImageError: hasImage
                          ? (_, _) {}
                          : null,
                      child: hasImage
                          ? null
                          : Text(
                              _initials,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: _activityColor(context),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: theme.colorScheme.surface,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: AppSpacing.md),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      friend.username,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          _activityLabel(),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: _activityColor(context),
                          ),
                        ),
                        if (friend.karmaPoints > 0) ...[
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            '•',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.outline,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Icon(
                            AppIcons.karma,
                            size: AppIcons.xs,
                            color: Colors.orange,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '${friend.karmaPoints}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                        if (friend.isInLobby) ...[
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            '•',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.outline,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Trong phòng',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (friend.mutualFriendsCount != null &&
                        friend.mutualFriendsCount! > 0) ...[
                      const SizedBox(height: 2),
                      Text(
                        '${friend.mutualFriendsCount} bạn chung',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Trailing actions
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                onSelected: (value) {
                  switch (value) {
                    case 'invite':
                      onInviteToLobby?.call();
                      break;
                    case 'unfriend':
                      onUnfriend?.call();
                      break;
                  }
                },
                itemBuilder: (context) => [
                  if (onInviteToLobby != null)
                    const PopupMenuItem(
                      value: 'invite',
                      child: Row(
                        children: [
                          Icon(AppIcons.add, size: AppIcons.sm),
                          SizedBox(width: AppSpacing.sm),
                          Text('Mời vào phòng'),
                        ],
                      ),
                    ),
                  if (onUnfriend != null)
                    const PopupMenuItem(
                      value: 'unfriend',
                      child: Row(
                        children: [
                          Icon(AppIcons.userRemove,
                              size: AppIcons.sm, color: Colors.red),
                          SizedBox(width: AppSpacing.sm),
                          Text('Hủy kết bạn',
                              style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}