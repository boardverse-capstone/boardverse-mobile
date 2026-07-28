import 'package:flutter/material.dart';

import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/entities.dart';
import 'shared/common_widgets.dart';
import 'shared/time_ago.dart';

/// Card hiển thị 1 friend request trong Inbox (received requests).
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return OutlinedCard(
      borderColor: request.isRead
          ? theme.colorScheme.outlineVariant.withValues(alpha: 0.6)
          : theme.colorScheme.primary.withValues(alpha: 0.4),
      borderWidth: request.isRead ? 1 : 1.5,
      radius: AppRadius.radiusMd,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(theme),
            if (request.message != null && request.message!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              _buildMessage(theme),
            ],
            if (request.mutualFriendsCount != null &&
                request.mutualFriendsCount! > 0) ...[
              const SizedBox(height: AppSpacing.xs),
              _buildMutualInfo(theme),
            ],
            const SizedBox(height: AppSpacing.md),
            _buildActions(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Row(
      children: [
        UserAvatar(
          username: request.requesterName,
          avatarUrl: request.requesterAvatar,
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
                      request.requesterName,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: request.isRead
                            ? FontWeight.w600
                            : FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (!request.isRead) ...[
                    const SizedBox(width: 6),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 2),
              Text(
                formatTimeAgo(request.createdAt),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMessage(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.radiusSm),
      ),
      child: Text(
        request.message!,
        style: theme.textTheme.bodySmall?.copyWith(
          fontStyle: FontStyle.italic,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildMutualInfo(ThemeData theme) {
    return Row(
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
    );
  }

  Widget _buildActions(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onDecline,
            icon: const Icon(Icons.close, size: AppIcons.sm),
            label: const Text('Từ chối'),
            style: OutlinedButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
              side: BorderSide(color: theme.colorScheme.outlineVariant),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: FilledButton.icon(
            onPressed: onAccept,
            icon: const Icon(AppIcons.check, size: AppIcons.sm),
            label: const Text('Chấp nhận'),
          ),
        ),
      ],
    );
  }
}
