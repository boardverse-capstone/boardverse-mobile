import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';
import '../../domain/entities/lobby_invite_entity.dart';

/// Modern lobby invite card với gradient accent và elevated design.
class LobbyInviteCard extends StatelessWidget {
  final LobbyInviteEntity invite;
  final bool isInvitee;
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

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: AppRadius.radiusLgAll,
        border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.5)),
        boxShadow: AppElevation.shadowMd,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: AppRadius.radiusLgAll,
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            // ── Header with gradient ──────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [colors.primary, colors.primary.withAlpha(204)],
                ),
              ),
              child: Row(
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
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
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
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          invite.gameName,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _StatusBadge(status: invite.status),
                ],
              ),
            ),

            // ── Body ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                children: [
                  // Message
                  if (invite.message != null && invite.message!.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: colors.surfaceContainerHighest.withValues(alpha: 0.5),
                        borderRadius: AppRadius.radiusSmAll,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.format_quote, size: 16, color: colors.primary),
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
                    const SizedBox(height: AppSpacing.md),
                  ],

                  // Info chips
                  Row(
                    children: [
                      _InfoChip(icon: AppIcons.cafe, label: invite.cafeName),
                      const SizedBox(width: AppSpacing.sm),
                      _InfoChip(
                        icon: AppIcons.users,
                        label: '${invite.currentMembers}/${invite.maxMembers}',
                      ),
                      const Spacer(),
                      if (invite.status == LobbyInviteStatus.pending &&
                          invite.remainingTime.inMinutes > 0)
                        _ExpiryChip(remaining: invite.remainingTime),
                    ],
                  ),

                  // Action buttons
                  if (invite.status == LobbyInviteStatus.pending && invite.isActive) ...[
                    const SizedBox(height: AppSpacing.md),
                    if (isInvitee && invite.hasSlots)
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: isLoading ? null : onDecline,
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                                shape: RoundedRectangleBorder(
                                  borderRadius: AppRadius.radiusMdAll,
                                ),
                              ),
                              child: isLoading
                                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                                  : const Text('Từ chối'),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            flex: 2,
                            child: _GradientButton(
                              label: 'Tham gia',
                              icon: AppIcons.userAdd,
                              onPressed: isLoading ? null : onAccept,
                              isLoading: isLoading,
                            ),
                          ),
                        ],
                      )
                    else if (!isInvitee)
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: isLoading ? null : onCancel,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.error,
                            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                            shape: RoundedRectangleBorder(
                              borderRadius: AppRadius.radiusMdAll,
                            ),
                          ),
                          child: isLoading
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Text('Hủy lời mời'),
                        ),
                      )
                    else
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.1),
                          borderRadius: AppRadius.radiusSmAll,
                          border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.warning_amber_rounded, size: 20, color: AppColors.warning),
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final LobbyInviteStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (status) {
      LobbyInviteStatus.pending => (Colors.white.withValues(alpha: 0.25), 'Chờ'),
      LobbyInviteStatus.accepted => (AppColors.success, 'Đã chấp nhận'),
      LobbyInviteStatus.declined => (AppColors.error, 'Đã từ chối'),
      LobbyInviteStatus.cancelled => (AppColors.error, 'Đã hủy'),
      LobbyInviteStatus.expired => (AppColors.textSecondary, 'Hết hạn'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
      decoration: BoxDecoration(
        color: color == Colors.white.withValues(alpha: 0.25)
            ? Colors.white.withValues(alpha: 0.2)
            : color.withValues(alpha: 0.15),
        borderRadius: AppRadius.radiusXxsAll,
        border: color == Colors.white.withValues(alpha: 0.25)
            ? Border.all(color: Colors.white.withValues(alpha: 0.3))
            : null,
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color == Colors.white.withValues(alpha: 0.25) ? Colors.white : color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: AppRadius.radiusSmAll,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: colors.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(color: colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _ExpiryChip extends StatelessWidget {
  final Duration remaining;

  const _ExpiryChip({required this.remaining});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUrgent = remaining.inHours < 1;
    final color = isUrgent ? AppColors.warning : AppColors.textSecondary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: AppRadius.radiusSmAll,
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer_outlined, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            'Còn ${_format(remaining)}',
            style: theme.textTheme.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  String _format(Duration d) {
    if (d.inHours > 0) return '${d.inHours}h';
    if (d.inMinutes > 0) return '${d.inMinutes}p';
    return '${d.inSeconds}s';
  }
}

/// Modern gradient primary button cho invite actions.
class _GradientButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool isLoading;

  const _GradientButton({
    required this.label,
    required this.icon,
    this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colors.primary, colors.primary.withAlpha(204)],
        ),
        borderRadius: AppRadius.radiusMdAll,
        boxShadow: [
          BoxShadow(
            color: colors.primary.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: AppRadius.radiusMdAll,
        child: InkWell(
          onTap: onPressed,
          borderRadius: AppRadius.radiusMdAll,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isLoading)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                else ...[
                  Icon(icon, size: 16, color: Colors.white),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
