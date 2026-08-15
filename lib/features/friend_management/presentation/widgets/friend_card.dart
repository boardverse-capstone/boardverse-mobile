import 'package:flutter/material.dart';

import 'package:boardverse/core/theme/app_colors.dart';
import 'package:boardverse/core/theme/app_spacing.dart';
import 'package:boardverse/core/theme/app_icons.dart';
import '../../domain/entities/entities.dart';
import 'common/common.dart';
import 'shared/activity_status_helpers.dart';
import 'shared/meta_row.dart';

/// Neo-brutalism Row card displaying a single friend in the friends list.
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
      radius: 14,
      shadowColor: AppColors.black.withValues(alpha: 0.06),
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
                      fontWeight: FontWeight.w900,
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

class _ActivityDotSize {
  _ActivityDotSize._();

  static const double dotSize = 14.0;
  static const double borderWidth = 2.5;
  static const double lobbyDotSize = 6.0;
}

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
                  color: AppColors.white,
                  width: _ActivityDotSize.borderWidth,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.black,
                    blurRadius: 0,
                    offset: Offset(1, 1),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

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
    if (isInLobby) {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 3,
        ),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.black, width: 1.5),
          boxShadow: const [
            BoxShadow(
              color: AppColors.black,
              blurRadius: 0,
              offset: Offset(2, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: _ActivityDotSize.lobbyDotSize,
              height: _ActivityDotSize.lobbyDotSize,
              decoration: const BoxDecoration(
                color: AppColors.white,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            const Text(
              'TRONG PHÒNG',
              style: TextStyle(
                color: AppColors.white,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
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
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.isInLobby,
    required this.onPressed,
  });

  final bool isInLobby;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final color = isInLobby ? AppColors.secondary : AppColors.primary;
    final label = isInLobby ? 'VÀO PHÒNG' : 'MỜI';
    final icon = isInLobby ? Icons.meeting_room_outlined : Icons.add_circle_outline;

    return SizedBox(
      height: 36,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.black, width: 1.5),
          boxShadow: const [
            BoxShadow(
              color: AppColors.black,
              blurRadius: 0,
              offset: Offset(2, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: onPressed,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: AppIcons.sm, color: AppColors.white),
                  const SizedBox(width: 4),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.white,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}