import 'package:flutter/material.dart';

import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/entities.dart';
import 'shared/activity_status_helpers.dart';
import 'shared/common_widgets.dart';
import 'shared/time_ago.dart';

/// Card hiển thị 1 friend request trong Inbox (received requests).
///
/// Redesign mobile-first:
/// - Header: avatar tier + tên + thời gian + unread dot.
/// - Message bubble (optional).
/// - Mutual friends info (optional).
/// - Actions: Từ chối / Chấp nhận — 2 nút lớn, full-width, dễ tap.
class FriendRequestCard extends StatelessWidget {
  const FriendRequestCard({
    super.key,
    required this.request,
    this.onAccept,
    this.onDecline,
    this.onTap,
  });

  final FriendRequestEntity request;
  final VoidCallback? onAccept;
  final VoidCallback? onDecline;
  final VoidCallback? onTap;

  String get _displayName {
    if (request.requesterName.isNotEmpty) return request.requesterName;
    final id = request.requesterId;
    if (id.isEmpty) return 'Người dùng';
    final shortId = id.length >= 8 ? id.substring(0, 8) : id;
    return 'User #$shortId';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tierColor = request.gamerTier?.color ?? theme.colorScheme.outline;
    final hasTier = request.gamerTier != null;

    return OutlinedCard(
      borderColor: request.isRead
          ? theme.colorScheme.outlineVariant.withValues(alpha: 0.5)
          : theme.colorScheme.primary.withValues(alpha: 0.5),
      borderWidth: request.isRead ? 1 : 2,
      radius: AppRadius.radiusLg,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: avatar + name + meta
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                hasTier
                    ? TieredAvatar(
                        username: _displayName,
                        avatarUrl: request.requesterAvatar,
                        borderColor: tierColor,
                        radius: 28,
                      )
                    : UserAvatar(
                        username: _displayName,
                        avatarUrl: request.requesterAvatar,
                        radius: 28,
                      ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              _displayName,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: request.isRead
                                    ? FontWeight.w600
                                    : FontWeight.bold,
                                color: request.requesterName.isEmpty
                                    ? theme.colorScheme.outline
                                    : null,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (!request.isRead) ...[
                            const SizedBox(width: 6),
                            Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                color: Color(0xFFE53935),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.schedule,
                            size: 13,
                            color: theme.colorScheme.outline,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            formatTimeAgo(request.createdAt),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.outline,
                            ),
                          ),
                          if (request.karmaPoints != null) ...[
                            const SizedBox(width: AppSpacing.xs),
                            Text(
                              '•',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.outline,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Icon(
                              AppIcons.karma,
                              size: 13,
                              color: Colors.orange.shade400,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '${request.karmaPoints}',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Message bubble
            if (request.message != null && request.message!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(AppRadius.radiusMd),
                ),
                child: Text(
                  request.message!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],

            // Mutual friends
            if (request.mutualFriendsCount != null &&
                request.mutualFriendsCount! > 0) ...[
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  Icon(
                    Icons.people_alt_outlined,
                    size: 14,
                    color: theme.colorScheme.outline,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${request.mutualFriendsCount} bạn chung',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: AppSpacing.md),

            // Action buttons — large, full-width for easy mobile tap
            _ActionButtons(
              onAccept: onAccept,
              onDecline: onDecline,
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({
    required this.onAccept,
    required this.onDecline,
  });

  final VoidCallback? onAccept;
  final VoidCallback? onDecline;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 44,
            child: OutlinedButton.icon(
              onPressed: onDecline,
              icon: const Icon(Icons.close, size: 18),
              label: const Text('Từ chối'),
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.colorScheme.error,
                side: BorderSide(color: theme.colorScheme.outlineVariant),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.radiusMd),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          flex: 2,
          child: SizedBox(
            height: 44,
            child: FilledButton.icon(
              onPressed: onAccept,
              icon: const Icon(AppIcons.check, size: 18),
              label: const Text('Chấp nhận'),
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.radiusMd),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
