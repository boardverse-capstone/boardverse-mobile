import 'package:flutter/material.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/entities.dart';
import 'shared/common_widgets.dart';

/// Card hiển thị kết quả tìm kiếm user (tab Tìm kiếm).
///
/// Redesign mobile-first: compact card với avatar, tên, karma,
/// nút action ở cuối thay đổi theo `friendshipStatus`.
///
/// Actions:
/// - `none` / `null` → "Kết bạn" (primary button)
/// - `pendingSent`  → disabled "Đã gửi"
/// - `pendingReceived` → disabled "Chờ bạn chấp nhận"
/// - `accepted`     → disabled "Bạn bè"
/// - `blocked`      → disabled "Đã chặn"
class UserSearchCard extends StatelessWidget {
  const UserSearchCard({
    super.key,
    required this.user,
    this.onSendRequest,
    this.onTap,
  });

  final UserSearchEntity user;
  final VoidCallback? onSendRequest;

  /// Tap trên card — mở chi tiết player.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return OutlinedCard(
      onTap: onTap,
      radius: AppRadius.radiusMd,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Row(
          children: [
            UserAvatar(
              username: user.username,
              avatarUrl: user.avatarUrl,
              radius: 24,
            ),
            const SizedBox(width: AppSpacing.sm),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
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
                  _MetaRow(
                    karmaPoints: user.karmaPoints,
                    mutualFriendsCount: user.mutualFriendsCount,
                  ),
                ],
              ),
            ),

            const SizedBox(width: AppSpacing.sm),
            _buildAction(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildAction(ThemeData theme) {
    switch (user.friendshipStatus) {
      case FriendshipStatus.none:
      case null:
        return SizedBox(
          height: 36,
          child: FilledButton(
            onPressed: onSendRequest,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.radiusMd),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.person_add_alt_1_outlined, size: 16),
                SizedBox(width: 4),
                Text('Kết bạn', style: TextStyle(fontSize: 12)),
              ],
            ),
          ),
        );
      case FriendshipStatus.pendingSent:
        return _StatusChip(
          icon: Icons.schedule,
          label: 'Đã gửi',
          color: theme.colorScheme.outline,
        );
      case FriendshipStatus.pendingReceived:
        return _StatusChip(
          icon: Icons.inbox_outlined,
          label: 'Chờ phản hồi',
          color: theme.colorScheme.primary,
        );
      case FriendshipStatus.accepted:
        return _StatusChip(
          icon: Icons.check_circle_outline,
          label: 'Bạn bè',
          color: Colors.green.shade600,
        );
      case FriendshipStatus.blocked:
        return _StatusChip(
          icon: Icons.block,
          label: 'Đã chặn',
          color: theme.colorScheme.error,
        );
    }
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({
    required this.karmaPoints,
    required this.mutualFriendsCount,
  });

  final int karmaPoints;
  final int mutualFriendsCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = <Widget>[
      Icon(
        Icons.local_fire_department_outlined,
        size: 13,
        color: Colors.orange.shade400,
      ),
      const SizedBox(width: 2),
      Text(
        '$karmaPoints',
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    ];

    if (mutualFriendsCount > 0) {
      items.add(const SizedBox(width: AppSpacing.xs));
      items.add(Text(
        '•',
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.outline,
        ),
      ));
      items.add(const SizedBox(width: AppSpacing.xs));
      items.add(Icon(
        Icons.people_alt_outlined,
        size: 13,
        color: theme.colorScheme.outline,
      ));
      items.add(const SizedBox(width: 2));
      items.add(Text(
        '$mutualFriendsCount',
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.outline,
        ),
      ));
    }

    return Row(children: items);
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
