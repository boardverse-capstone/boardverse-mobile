import 'package:flutter/material.dart';

import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/entities.dart';
import 'shared/activity_status_helpers.dart';
import 'shared/common_widgets.dart';

/// Card hiển thị 1 người bạn trong danh sách Friends.
///
/// Redesign mobile-first:
/// - Card vuông, hiển thị avatar lớn (72x72) làm tâm.
/// - Tên + trạng thái hoạt động rõ ràng.
/// - 2 icon action trực tiếp bên dưới avatar (mời phòng / xem profile).
/// - Không dùng popup menu nhỏ — touch target rõ ràng trên màn hình mobile.
class FriendCard extends StatelessWidget {
  const FriendCard({
    super.key,
    required this.friend,
    this.onTap,
    this.onInviteToLobby,
  });

  final FriendEntity friend;

  /// Tap trên card — mở chi tiết profile.
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
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Avatar + status dot
            _AvatarSection(
              username: friend.username,
              avatarUrl: friend.avatarUrl,
              tierColor: tierColor,
              activityColor: badge.color ?? theme.colorScheme.outline,
            ),
            const SizedBox(height: 6),

            // Username
            Text(
              friend.username,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),

            // Trạng thái hoạt động
            _ActivityChip(
              label: badge.label,
              color: badge.color ?? theme.colorScheme.outline,
              isInLobby: friend.isInLobby,
            ),

            // Karma + bạn chung
            if (friend.karmaPoints > 0 || friend.mutualFriendsCount != null) ...[
              const SizedBox(height: 2),
              _MetaRow(
                karmaPoints: friend.karmaPoints,
                mutualFriendsCount: friend.mutualFriendsCount,
              ),
            ],

            const SizedBox(height: 8),

            // Action button
            SizedBox(
              width: double.infinity,
              height: 36,
              child: FilledButton.icon(
                onPressed: onInviteToLobby,
                icon: Icon(
                  friend.isInLobby ? Icons.meeting_room_outlined : Icons.add_circle_outline,
                  size: 16,
                ),
                label: Text(
                  friend.isInLobby ? 'Vào phòng' : 'Mời',
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
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
    return Stack(
      children: [
        TieredAvatar(
          username: username,
          avatarUrl: avatarUrl,
          borderColor: tierColor,
          radius: 36,
        ),
        Positioned(
          right: 0,
          bottom: 0,
          child: Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: activityColor,
              shape: BoxShape.circle,
              border: Border.all(
                color: Theme.of(context).colorScheme.surface,
                width: 2.5,
              ),
            ),
          ),
        ),
      ],
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
    final theme = Theme.of(context);

    if (isInLobby) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5),
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
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 5),
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

class _MetaRow extends StatelessWidget {
  const _MetaRow({
    required this.karmaPoints,
    required this.mutualFriendsCount,
  });

  final int? karmaPoints;
  final int? mutualFriendsCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = <Widget>[];

    if (karmaPoints != null && karmaPoints! > 0) {
      items.add(Icon(
        AppIcons.karma,
        size: 14,
        color: Colors.orange.shade400,
      ));
      items.add(const SizedBox(width: 2));
      items.add(Text(
        '$karmaPoints',
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ));
    }

    if (mutualFriendsCount != null && mutualFriendsCount! > 0) {
      if (items.isNotEmpty) {
        items.add(const SizedBox(width: AppSpacing.xs));
        items.add(Text(
          '•',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.outline,
          ),
        ));
        items.add(const SizedBox(width: AppSpacing.xs));
      }
      items.add(Icon(
        Icons.people_alt_outlined,
        size: 14,
        color: theme.colorScheme.outline,
      ));
      items.add(const SizedBox(width: 2));
      items.add(Text(
        '$mutualFriendsCount bạn chung',
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.outline,
        ),
      ));
    }

    if (items.isEmpty) return const SizedBox.shrink();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: items,
    );
  }
}