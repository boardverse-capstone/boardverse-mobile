import 'package:flutter/material.dart';

import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/entities.dart';
import 'shared/activity_status_helpers.dart';
import 'shared/common_widgets.dart';

/// Card hiển thị 1 người bạn trong danh sách Friends.
///
/// Cấu trúc: avatar có viền tier + dot online + username + activity/karma/
/// lobby status + popup menu (invite lobby / unfriend).
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tierColor = friend.gamerTier?.color ?? theme.colorScheme.outline;
    final activityBadge = ActivityStatusBadge.of(friend.activityStatus);

    return OutlinedCard(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            _buildAvatarWithDot(theme, tierColor),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: _buildInfo(theme, activityBadge)),
            _buildPopupMenu(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarWithDot(ThemeData theme, Color tierColor) {
    return Stack(
      children: [
        TieredAvatar(
          username: friend.username,
          avatarUrl: friend.avatarUrl,
          borderColor: tierColor,
        ),
        Positioned(
          right: 0,
          bottom: 0,
          child: Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: _effectiveActivityColor(theme),
              shape: BoxShape.circle,
              border: Border.all(
                color: theme.colorScheme.surface,
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Color _effectiveActivityColor(ThemeData theme) {
    final badge = ActivityStatusBadge.of(friend.activityStatus);
    return badge.color ?? theme.colorScheme.outline;
  }

  Widget _buildInfo(ThemeData theme, ActivityStatusBadge badge) {
    return Column(
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
              badge.label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: badge.color ?? theme.colorScheme.outline,
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
              const Icon(AppIcons.karma, size: AppIcons.xs, color: Colors.orange),
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
              _LobbyBadge(),
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
    );
  }

  Widget _buildPopupMenu(ThemeData theme) {
    return PopupMenuButton<String>(
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
    );
  }
}

class _LobbyBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'Trong phòng',
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
