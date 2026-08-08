import 'package:flutter/material.dart';

import 'package:boardverse_mobile/core/theme/app_colors.dart';
import 'package:boardverse_mobile/core/theme/app_icons.dart';
import 'package:boardverse_mobile/core/theme/app_spacing.dart';
import 'package:boardverse_mobile/core/theme/neo_brutalism_theme.dart';
import '../../domain/entities/entities.dart';

/// Neo-brutalism Action panel for FriendProfilePage.
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.borderDark : AppColors.border;

    if (profile.hasBlockedMe) {
      return _Notice(
        icon: Icons.lock_outline,
        color: AppColors.error,
        text: 'Người chơi này hiện không nhận tương tác từ bạn.',
      );
    }

    if (profile.isBlockedByMe) {
      return _NeoActionButton(
        label: 'BỎ CHẶN',
        icon: AppIcons.unlock,
        color: AppColors.secondary,
        borderColor: borderColor,
        onPressed: isMutating ? null : onUnblock,
      );
    }

    switch (profile.friendshipStatus) {
      case FriendshipStatus.accepted:
        return Row(
          children: [
            Expanded(
              child: _NeoActionButton(
                label: 'MỜI VÀO PHÒNG',
                icon: AppIcons.add,
                color: AppColors.primary,
                borderColor: borderColor,
                onPressed: isMutating ? null : onInviteToLobby,
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
          color: AppColors.warning,
          text: 'Bạn đã gửi lời mời. Đang chờ phản hồi.',
        );
      case FriendshipStatus.pendingReceived:
        return const _Notice(
          icon: AppIcons.inbox,
          color: AppColors.primary,
          text: 'Người chơi này đã gửi lời mời cho bạn. Mở tab "Lời mời" để phản hồi.',
        );
      case FriendshipStatus.blocked:
        return const _Notice(
          icon: AppIcons.lock,
          color: AppColors.error,
          text: 'Bạn đã chặn người chơi này.',
        );
      case FriendshipStatus.none:
        if (!profile.canSendFriendRequest) {
          return const _Notice(
            icon: Icons.do_not_disturb_on_outlined,
            color: AppColors.textSecondary,
            text: 'Người chơi này hiện không nhận lời mời kết bạn.',
          );
        }
        return Row(
          children: [
            Expanded(
              child: _NeoActionButton(
                label: 'KẾT BẠN',
                icon: AppIcons.userAdd,
                color: AppColors.primary,
                borderColor: borderColor,
                onPressed: isMutating ? null : onSendRequest,
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
    final items = <PopupMenuEntry<String>>[];

    if (onUnfriend != null) {
      items.add(_buildMenuItem(
        value: 'unfriend',
        icon: AppIcons.userRemove,
        label: 'Hủy kết bạn',
      ));
    }
    if (onBlock != null) {
      items.add(_buildMenuItem(
        value: 'block',
        icon: AppIcons.lock,
        label: 'Chặn người chơi',
      ));
    }
    if (onReport != null) {
      items.add(_buildMenuItem(
        value: 'report',
        icon: AppIcons.flag,
        label: 'Báo cáo vi phạm',
      ));
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.black, width: 2),
        boxShadow: const [
          BoxShadow(
            color: AppColors.black,
            blurRadius: 0,
            offset: Offset(2, 2),
          ),
        ],
      ),
      child: PopupMenuButton<String>(
        icon: const Icon(
          Icons.more_vert,
          color: AppColors.black,
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
  }) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: AppIcons.sm, color: AppColors.error),
          const SizedBox(width: AppSpacing.sm),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.error,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({
    required this.icon,
    required this.color,
    required this.text,
  });

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm + 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 2),
        boxShadow: NeoBrutalismTheme.lightShadow(
          shadowColor: color.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.black, width: 1.5),
            ),
            child: Icon(icon, color: AppColors.white, size: AppIcons.md),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Neo-brutalism action button.
class _NeoActionButton extends StatelessWidget {
  const _NeoActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.borderColor,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final Color color;
  final Color borderColor;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.black, width: 2),
        boxShadow: NeoBrutalismTheme.lightShadow(
          shadowColor: color.withValues(alpha: 0.5),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: AppColors.white, size: 18),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}