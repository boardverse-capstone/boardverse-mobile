import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/entities.dart';
import 'shared/common_widgets.dart';

/// Card hiển thị kết quả tìm kiếm user (tab Tìm kiếm).
///
/// Nút action ở cuối card thay đổi theo `friendshipStatus`:
/// - `none` / `null` → FilledButton "Kết bạn" (gọi [onSendRequest]).
/// - `pendingSent` → OutlinedButton disabled "Đã gửi".
/// - `pendingReceived` → OutlinedButton disabled "Chờ bạn chấp nhận".
/// - `accepted` → OutlinedButton disabled "Bạn bè".
/// - `blocked` → OutlinedButton disabled "Đã chặn".
class UserSearchCard extends StatelessWidget {
  const UserSearchCard({
    super.key,
    required this.user,
    this.onSendRequest,
  });

  final UserSearchEntity user;
  final VoidCallback? onSendRequest;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return OutlinedCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            UserAvatar(
              username: user.username,
              avatarUrl: user.avatarUrl,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: _buildInfo(theme)),
            const SizedBox(width: AppSpacing.sm),
            _buildAction(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfo(ThemeData theme) {
    return Column(
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
    );
  }

  Widget _buildAction() {
    switch (user.friendshipStatus) {
      case FriendshipStatus.none:
      case null:
        return FilledButton.icon(
          onPressed: onSendRequest,
          icon: const Icon(Icons.person_add_alt_1_outlined, size: 16),
          label: const Text('Kết bạn'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12),
          ),
        );
      case FriendshipStatus.pendingSent:
        return OutlinedButton.icon(
          onPressed: null,
          icon: const Icon(Icons.schedule, size: 16),
          label: const Text('Đã gửi'),
        );
      case FriendshipStatus.pendingReceived:
        return OutlinedButton.icon(
          onPressed: null,
          icon: const Icon(Icons.inbox_outlined, size: 16),
          label: const Text('Chờ bạn chấp nhận'),
        );
      case FriendshipStatus.accepted:
        return OutlinedButton.icon(
          onPressed: null,
          icon: const Icon(Icons.check_circle_outline, size: 16),
          label: const Text('Bạn bè'),
        );
      case FriendshipStatus.blocked:
        return OutlinedButton.icon(
          onPressed: null,
          icon: const Icon(Icons.block, size: 16),
          label: const Text('Đã chặn'),
        );
    }
  }
}
