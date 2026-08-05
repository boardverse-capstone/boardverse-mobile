import 'package:flutter/material.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_icons.dart';
import '../../domain/entities/entities.dart';
import 'common/common.dart';
import 'shared/activity_status_helpers.dart';
import 'shared/meta_row.dart';

/// Row card displaying a single friend in the friends list.
///
/// Features:
/// - Avatar 56x56 with gamer-tier border and activity dot
/// - Username and status pill (online/offline/in lobby)
/// - Karma + mutual friends meta row
/// - Action button (Invite to lobby)
class FriendCard extends StatelessWidget {
  const FriendCard({
    super.key,
    required this.friend,
    this.onTap,
    this.onInviteToLobby,
  });

  final FriendEntity friend;
  final VoidCallback? onTap;
  final VoidCallback? onInviteToLobby;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tierColor = friend.gamerTier?.color ?? theme.colorScheme.outline;
    final badge = ActivityStatusBadge.of(friend.activityStatus);

    return OutlinedCard(
      onTap: onTap,
      radius: AppRadius.radiusLg,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _AvatarSection(
              username: friend.username,
              avatarUrl: friend.avatarUrl,
              tierColor: tierColor,
              activityColor: badge.color ?? theme.colorScheme.outline,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    friend.username,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  _ActivityChip(
                    label: badge.label,
                    color: badge.color ?? theme.colorScheme.outline,
                    isInLobby: friend.isInLobby,
                  ),
                  if (friend.karmaPoints > 0 ||
                      (friend.mutualFriendsCount ?? 0) > 0) ...[
                    const SizedBox(height: AppSpacing.xs),
                    MetaRow(
                      karmaPoints: friend.karmaPoints,
                      mutualFriendsCount: friend.mutualFriendsCount,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            _ActionButton(
              isInLobby: friend.isInLobby,
              onPressed: onInviteToLobby,
            ),
          ],
        ),
      ),
    );
  }
}

/// Activity dot size constants
class _ActivityDotSize {
  _ActivityDotSize._();

  static const double dotSize = 14.0;
  static const double borderWidth = 2.5;
  static const double lobbyDotSize = 6.0;
}

/// Avatar section with tier border and activity status dot.
class _AvatarSection extends StatelessWidget {
  const _AvatarSection({
    required this.username,
    required this.avatarUrl,
    required this.tierColor,
    required this.activityColor,
  });

  final String username;
  final String avatarUrl;
  final Color tierColor;
  final Color activityColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56,
      height: 56,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Center(
            child: TieredAvatar(
              username: username,
              avatarUrl: avatarUrl,
              borderColor: tierColor,
              radius: 26,
              borderWidth: 2,
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: _ActivityDotSize.dotSize,
              height: _ActivityDotSize.dotSize,
              decoration: BoxDecoration(
                color: activityColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).colorScheme.surface,
                  width: _ActivityDotSize.borderWidth,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Activity chip showing online/offline/in lobby status.
class _ActivityChip extends StatelessWidget {
  const _ActivityChip({
    required this.label,
    required this.color,
    required this.isInLobby,
  });

  final String label;
  final Color color;
  final bool isInLobby;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (isInLobby) {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xxs,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.12),
          borderRadius: AppRadius.radiusSmAll,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: _ActivityDotSize.lobbyDotSize,
              height: _ActivityDotSize.lobbyDotSize,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: AppSpacing.xxs),
            Text(
              'Trong phòng',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: _ActivityDotSize.lobbyDotSize,
          height: _ActivityDotSize.lobbyDotSize,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: AppSpacing.xxs),
        Flexible(
          child: Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(color: color),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// Action button for inviting to lobby or joining.
class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.isInLobby,
    required this.onPressed,
  });

  final bool isInLobby;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    if (isInLobby) {
      return SizedBox(
        height: 36,
        child: FilledButton.icon(
          onPressed: onPressed,
          icon: const Icon(Icons.meeting_room_outlined, size: AppIcons.sm),
          label: const Text('Vào phòng', style: TextStyle(fontSize: 12)),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            shape: RoundedRectangleBorder(
              borderRadius: AppRadius.radiusMdAll,
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 36,
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.add_circle_outline, size: AppIcons.sm),
        label: const Text('Mời', style: TextStyle(fontSize: 12)),
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.radiusMdAll,
          ),
        ),
      ),
    );
  }
}
