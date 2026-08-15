import 'package:flutter/material.dart';

import 'package:boardverse/core/theme/app_colors.dart';
import 'package:boardverse/core/theme/app_icons.dart';
import 'package:boardverse/core/theme/app_spacing.dart';
import 'package:boardverse/core/theme/neo_brutalism_theme.dart';
import '../../domain/entities/entities.dart';
import 'common/common.dart';
import 'shared/activity_status_helpers.dart';
import 'shared/time_ago.dart';

/// Neo-brutalism Card displaying a friend request in the inbox.
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
    final isDark = theme.brightness == Brightness.dark;
    final tierColor = request.gamerTier?.color ?? theme.colorScheme.outline;
    final hasTier = request.gamerTier != null;
    final borderColor = request.isRead
        ? (isDark ? AppColors.borderDark : AppColors.border)
        : AppColors.primary;

    return OutlinedCard(
      borderColor: borderColor,
      borderWidth: request.isRead
          ? NeoBrutalismTheme.borderWidth
          : NeoBrutalismTheme.borderWidthBold,
      radius: 14,
      shadowColor: request.isRead
          ? AppColors.black.withValues(alpha: 0.05)
          : AppColors.primary.withValues(alpha: 0.3),
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
                        fontWeight: isRead ? FontWeight.w700 : FontWeight.w900,
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
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.black, width: 1),
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
                    style: TextStyle(
                      color: theme.colorScheme.outline,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (karmaPoints != null && karmaPoints! > 0) ...[
                    const SizedBox(width: AppSpacing.xs),
                    const Text('·',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w900,
                        )),
                    const SizedBox(width: AppSpacing.xs),
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: AppColors.warning,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.black, width: 1),
                      ),
                      child: const Icon(
                        AppIcons.karma,
                        size: 10,
                        color: AppColors.black,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '$karmaPoints',
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w900,
                        fontSize: 11,
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
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceVariant : AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(
            color: AppColors.primary,
            width: 4,
          ),
          top: BorderSide(
            color: AppColors.primary.withValues(alpha: 0.3),
            width: 1.5,
          ),
          right: BorderSide(
            color: AppColors.primary.withValues(alpha: 0.3),
            width: 1.5,
          ),
          bottom: BorderSide(
            color: AppColors.primary.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        boxShadow: NeoBrutalismTheme.lightShadow(
          shadowColor: AppColors.black.withValues(alpha: 0.05),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.format_quote_rounded,
            size: 16,
            color: AppColors.primary,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w700,
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
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.secondary, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.people_alt_outlined,
            size: 14,
            color: AppColors.secondary,
          ),
          const SizedBox(width: 4),
          Text(
            '$count BẠN CHUNG',
            style: const TextStyle(
              color: AppColors.secondary,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
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
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 44,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.error, width: 2),
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
                  borderRadius: BorderRadius.circular(12),
                  onTap: onDecline,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.close, size: 18, color: AppColors.error),
                        SizedBox(width: 4),
                        Text(
                          'TỪ CHỐI',
                          style: TextStyle(
                            color: AppColors.error,
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: SizedBox(
            height: 44,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.success,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.black, width: 2),
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
                  borderRadius: BorderRadius.circular(12),
                  onTap: onAccept,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(AppIcons.check, size: 18, color: AppColors.white),
                        SizedBox(width: 4),
                        Text(
                          'CHẤP NHẬN',
                          style: TextStyle(
                            color: AppColors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}