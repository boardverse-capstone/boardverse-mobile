import 'package:flutter/material.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/entities.dart';
import 'common/common.dart';
import 'shared/meta_row.dart';
import 'shared/status_chip.dart';

/// Card displaying user search results.
///
/// Shows avatar, name, meta and action button that changes based on
/// `friendshipStatus`.
///
/// Actions based on status:
/// - `none` / `null` → "Kết bạn" (primary button)
/// - `pendingSent`  → disabled "Đã gửi"
/// - `pendingReceived` → disabled "Chờ phản hồi"
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
              radius: 22,
            ),
            const SizedBox(width: AppSpacing.md),
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
                  const SizedBox(height: 4),
                  MetaRow(
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
          child: FilledButton.icon(
            onPressed: onSendRequest,
            icon: const Icon(Icons.person_add_alt_1_outlined, size: 16),
            label: const Text('Kết bạn', style: TextStyle(fontSize: 12)),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.radiusMd),
              ),
            ),
          ),
        );
      case FriendshipStatus.pendingSent:
        return const StatusChip(
          icon: Icons.schedule,
          label: 'Đã gửi',
          color: Color(0xFF8B8B8B),
        );
      case FriendshipStatus.pendingReceived:
        return StatusChip(
          icon: Icons.inbox_outlined,
          label: 'Chờ phản hồi',
          color: theme.colorScheme.primary,
        );
      case FriendshipStatus.accepted:
        return const StatusChip(
          icon: Icons.check_circle_outline,
          label: 'Bạn bè',
          color: Color(0xFF2E7D32),
        );
      case FriendshipStatus.blocked:
        return StatusChip(
          icon: Icons.block,
          label: 'Đã chặn',
          color: theme.colorScheme.error,
        );
    }
  }
}
