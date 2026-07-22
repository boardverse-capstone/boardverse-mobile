import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';
import '../../domain/entities/lobby_invite_entity.dart';

/// Card hiển thị một lời mời tham gia lobby.
class LobbyInviteCard extends StatelessWidget {
  final LobbyInviteEntity invite;
  final bool isInvitee; // true nếu user là người được mời
  final VoidCallback? onAccept;
  final VoidCallback? onDecline;
  final VoidCallback? onCancel;
  final bool isLoading;

  const LobbyInviteCard({
    super.key,
    required this.invite,
    this.isInvitee = true,
    this.onAccept,
    this.onDecline,
    this.onCancel,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      elevation: AppElevation.elevationSm,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.radiusLg),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Avatar + Name + Status
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundImage: invite.inviterAvatar.isNotEmpty
                      ? NetworkImage(invite.inviterAvatar)
                      : null,
                  child: invite.inviterAvatar.isEmpty
                      ? Text(
                          invite.inviterName.isNotEmpty
                              ? invite.inviterName[0].toUpperCase()
                              : '?',
                          style: theme.textTheme.titleMedium,
                        )
                      : null,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isInvitee
                            ? '${invite.inviterName} mời bạn'
                            : 'Lời mời đã gửi',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        invite.gameName,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                _StatusBadge(status: invite.status),
              ],
            ),

            if (invite.message != null && invite.message!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHighest,
                  borderRadius: AppRadius.radiusSmAll,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.format_quote,
                      size: AppIcons.sm,
                      color: colors.onSurfaceVariant,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        invite.message!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontStyle: FontStyle.italic,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: AppSpacing.md),

            // Info: Cafe + Members
            Row(
              children: [
                Icon(
                  AppIcons.cafe,
                  size: AppIcons.sm,
                  color: colors.onSurfaceVariant,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  invite.cafeName,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                Icon(
                  AppIcons.users,
                  size: AppIcons.sm,
                  color: colors.onSurfaceVariant,
                ),
                const SizedBox(width: AppIcons.xs),
                Text(
                  '${invite.currentMembers}/${invite.maxMembers}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),

            // Expiry countdown
            if (invite.status == LobbyInviteStatus.pending &&
                invite.remainingTime.inMinutes > 0) ...[
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  Icon(
                    Icons.timer_outlined,
                    size: AppIcons.sm,
                    color: colors.onSurfaceVariant,
                  ),
                  const SizedBox(width: AppIcons.xs),
                  Text(
                    'Hết hạn trong ${_formatDuration(invite.remainingTime)}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: invite.remainingTime.inHours < 1
                          ? AppColors.warning
                          : colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],

            // Action buttons
            if (invite.status == LobbyInviteStatus.pending &&
                invite.isActive) ...[
              const SizedBox(height: AppSpacing.md),
              const Divider(),
              const SizedBox(height: AppSpacing.sm),
              if (isInvitee && invite.hasSlots) ...[
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: isLoading ? null : onDecline,
                        child: isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Từ chối'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      flex: 2,
                      child: FilledButton(
                        onPressed: isLoading ? null : onAccept,
                        child: const Text('Tham gia'),
                      ),
                    ),
                  ],
                ),
              ] else if (!isInvitee) ...[
                // Inviter có thể cancel
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: isLoading ? null : onCancel,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                    ),
                    child: isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Hủy lời mời'),
                  ),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.1),
                    borderRadius: AppRadius.radiusSmAll,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        size: AppIcons.md,
                        color: AppColors.warning,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          'Phòng đã đầy',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.warning,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}h';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}p';
    } else {
      return '${duration.inSeconds}s';
    }
  }
}

class _StatusBadge extends StatelessWidget {
  final LobbyInviteStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (status) {
      LobbyInviteStatus.pending => (AppColors.warning, 'Chờ'),
      LobbyInviteStatus.accepted => (AppColors.success, 'Đã chấp nhận'),
      LobbyInviteStatus.declined => (AppColors.error, 'Đã từ chối'),
      LobbyInviteStatus.cancelled => (AppColors.error, 'Đã hủy'),
      LobbyInviteStatus.expired => (AppColors.textSecondary, 'Hết hạn'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: AppRadius.radiusXxsAll,
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
