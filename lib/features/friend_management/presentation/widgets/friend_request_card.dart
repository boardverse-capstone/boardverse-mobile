import 'package:flutter/material.dart';

import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/entities.dart';
import 'common/common.dart';
import 'shared/activity_status_helpers.dart';
import 'shared/time_ago.dart';

/// Card displaying a friend request in the inbox (received requests).
///
/// Features:
/// - Header: tier avatar + name + time + unread dot
/// - Message bubble (optional)
/// - Mutual friends info (optional)
/// - Actions: Decline / Accept buttons
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
            _Header(
              displayName: _displayName,
              avatarUrl: request.requesterAvatar,
              tierColor: tierColor,
              hasTier: hasTier,
              isRead: request.isRead,
              createdAt: request.createdAt,
              karmaPoints: request.karmaPoints,
            ),
            if (request.message != null && request.message!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              _MessageBubble(message: request.message!),
            ],
            if (request.mutualFriendsCount != null &&
                request.mutualFriendsCount! > 0) ...[
              const SizedBox(height: AppSpacing.sm),
              _MutualFriendsChip(count: request.mutualFriendsCount!),
            ],
            const SizedBox(height: AppSpacing.md),
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

class _Header extends StatelessWidget {
  const _Header({
    required this.displayName,
    required this.avatarUrl,
    required this.tierColor,
    required this.hasTier,
    required this.isRead,
    required this.createdAt,
    this.karmaPoints,
  });

  final String displayName;
  final String avatarUrl;
  final Color tierColor;
  final bool hasTier;
  final bool isRead;
  final DateTime createdAt;
  final int? karmaPoints;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        hasTier
            ? TieredAvatar(
                username: displayName,
                avatarUrl: avatarUrl,
                borderColor: tierColor,
                radius: 26,
              )
            : UserAvatar(
                username: displayName,
                avatarUrl: avatarUrl,
                radius: 26,
              ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      displayName,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: isRead ? FontWeight.w600 : FontWeight.bold,
                        color: displayName == 'Người dùng'
                            ? theme.colorScheme.outline
                            : null,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (!isRead) ...[
                    const SizedBox(width: 6),
                    Container(
                      width: 8,
                      height: 8,
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
                    formatTimeAgo(createdAt),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                  if (karmaPoints != null && karmaPoints! > 0) ...[
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      '·',
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
                      '$karmaPoints',
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
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.radiusMd),
        border: Border(
          left: BorderSide(
            color: theme.colorScheme.primary.withValues(alpha: 0.4),
            width: 3,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.format_quote_rounded,
            size: 16,
            color: theme.colorScheme.primary.withValues(alpha: 0.6),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                fontStyle: FontStyle.italic,
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MutualFriendsChip extends StatelessWidget {
  const _MutualFriendsChip({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppRadius.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.people_alt_outlined,
            size: 14,
            color: theme.colorScheme.outline,
          ),
          const SizedBox(width: 4),
          Text(
            '$count bạn chung',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
        ],
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
                side: BorderSide(
                  color: theme.colorScheme.error.withValues(alpha: 0.4),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.radiusMd),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
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
