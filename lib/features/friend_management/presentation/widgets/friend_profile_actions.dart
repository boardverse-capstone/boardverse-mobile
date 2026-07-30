import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/entities.dart';
import '../cubit/cubit.dart';

/// Action panel for FriendProfilePage.
///
/// Changes based on `friendshipStatus` and permission flags from `FriendProfileEntity`.
class FriendProfileActions extends StatelessWidget {
  const FriendProfileActions({
    super.key,
    required this.profile,
    required this.isMutating,
    required this.onSendRequest,
    required this.onUnfriend,
    required this.onInviteToLobby,
    required this.onBlock,
    required this.onUnblock,
    required this.onReport,
  });

  final FriendProfileEntity profile;
  final bool isMutating;

  final VoidCallback onSendRequest;
  final VoidCallback onUnfriend;
  final VoidCallback onInviteToLobby;
  final VoidCallback onBlock;
  final VoidCallback onUnblock;
  final VoidCallback onReport;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (profile.hasBlockedMe) {
      return _Notice(
        icon: Icons.lock_outline,
        color: theme.colorScheme.outline,
        text: 'Người chơi này hiện không nhận tương tác từ bạn.',
      );
    }

    if (profile.isBlockedByMe) {
      return Row(
        children: [
          Expanded(
            child: FilledButton.icon(
              onPressed: isMutating ? null : onUnblock,
              icon: const Icon(AppIcons.unlock),
              label: const Text('Bỏ chặn'),
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.tertiary,
              ),
            ),
          ),
        ],
      );
    }

    switch (profile.friendshipStatus) {
      case FriendshipStatus.accepted:
        return Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: isMutating ? null : onInviteToLobby,
                icon: const Icon(AppIcons.add),
                label: const Text('Mời vào phòng'),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            _OverflowMenu(
              onUnfriend: onUnfriend,
              onReport: profile.canReport ? onReport : null,
            ),
          ],
        );
      case FriendshipStatus.pendingSent:
        return const _Notice(
          icon: AppIcons.pending,
          color: null,
          text: 'Bạn đã gửi lời mời. Đang chờ phản hồi.',
        );
      case FriendshipStatus.pendingReceived:
        return const _Notice(
          icon: AppIcons.inbox,
          color: null,
          text: 'Người chơi này đã gửi lời mời cho bạn. Mở tab "Lời mời" để phản hồi.',
        );
      case FriendshipStatus.blocked:
        return const _Notice(
          icon: AppIcons.lock,
          color: null,
          text: 'Bạn đã chặn người chơi này.',
        );
      case FriendshipStatus.none:
        if (!profile.canSendFriendRequest) {
          return const _Notice(
            icon: Icons.do_not_disturb_on_outlined,
            color: null,
            text: 'Người chơi này hiện không nhận lời mời kết bạn.',
          );
        }
        return Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: isMutating ? null : onSendRequest,
                icon: const Icon(AppIcons.userAdd),
                label: const Text('Kết bạn'),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            _OverflowMenu(
              onBlock: onBlock,
            ),
          ],
        );
    }
  }
}

class _OverflowMenu extends StatelessWidget {
  const _OverflowMenu({
    this.onUnfriend,
    this.onReport,
    this.onBlock,
  });

  final VoidCallback? onUnfriend;
  final VoidCallback? onReport;
  final VoidCallback? onBlock;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = <PopupMenuEntry<String>>[];

    if (onUnfriend != null) {
      items.add(_buildMenuItem(
        value: 'unfriend',
        icon: AppIcons.userRemove,
        label: 'Hủy kết bạn',
        isDestructive: true,
      ));
    }
    if (onBlock != null) {
      items.add(_buildMenuItem(
        value: 'block',
        icon: AppIcons.lock,
        label: 'Chặn người chơi',
        isDestructive: true,
      ));
    }
    if (onReport != null) {
      items.add(_buildMenuItem(
        value: 'report',
        icon: AppIcons.flag,
        label: 'Báo cáo vi phạm',
        isDestructive: true,
      ));
    }

    return Material(
      color: theme.colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: PopupMenuButton<String>(
        icon: Icon(
          Icons.more_vert,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        onSelected: (value) {
          switch (value) {
            case 'unfriend':
              onUnfriend?.call();
            case 'block':
              onBlock?.call();
            case 'report':
              onReport?.call();
          }
        },
        itemBuilder: (context) => items,
      ),
    );
  }

  PopupMenuItem<String> _buildMenuItem({
    required String value,
    required IconData icon,
    required String label,
    required bool isDestructive,
  }) {
    final color = isDestructive ? Colors.red : null;
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: AppIcons.sm, color: color),
          const SizedBox(width: AppSpacing.sm),
          Text(label, style: TextStyle(color: color)),
        ],
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({
    required this.icon,
    this.color,
    required this.text,
  });

  final IconData icon;
  final Color? color;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveColor = color ?? theme.colorScheme.outline;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: effectiveColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.sm),
      ),
      child: Row(
        children: [
          Icon(icon, color: effectiveColor, size: AppIcons.md),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(color: effectiveColor),
            ),
          ),
        ],
      ),
    );
  }
}

/// Helper for listening to profile action messages and showing snackbars.
void listenProfileActionMessage(BuildContext context, FriendProfileState state) {
  if (state is FriendProfileLoaded && state.actionMessage != null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(state.actionMessage!),
        duration: const Duration(seconds: 3),
      ),
    );
    context.read<FriendProfileCubit>().clearActionMessage();
  }
}
