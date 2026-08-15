import 'package:flutter/material.dart';

import 'package:boardverse/core/theme/app_colors.dart';
import 'package:boardverse/core/theme/app_icons.dart';
import 'package:boardverse/core/theme/app_spacing.dart';
import 'package:boardverse/features/friend_management/domain/entities/friend_entity.dart';

class OnlineFriendsList extends StatelessWidget {
  final List<FriendEntity> friends;
  final Function(FriendEntity)? onInvite;
  final Function(FriendEntity)? onAdd;
  final Function(FriendEntity)? onViewProfile;
  final ScrollController? controller;

  /// Set các friendId đã gửi lời mời thành công — tile sẽ disable nút
  /// "Mời" (đổi thành "Đã mời" + icon check) để user biết đã mời rồi.
  final Set<String> invitedFriendIds;

  /// Cờ bật/tắt nút "Thêm" trên mỗi friend tile.
  final bool showAddButton;

  const OnlineFriendsList({
    super.key,
    required this.friends,
    this.onInvite,
    this.onAdd,
    this.onViewProfile,
    this.controller,
    this.invitedFriendIds = const <String>{},
    this.showAddButton = false,
  });

  @override
  Widget build(BuildContext context) {
    if (friends.isEmpty) {
      return const _EmptyFriendsState();
    }

    return ListView.separated(
      controller: controller,
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      itemCount: friends.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.xs),
      itemBuilder: (context, index) {
        final friend = friends[index];
        return _FriendTile(
          friend: friend,
          alreadyInvited: invitedFriendIds.contains(friend.odId),
          onInvite: onInvite,
          onAdd: showAddButton ? onAdd : null,
          onViewProfile: onViewProfile,
        );
      },
    );
  }
}

class _FriendTile extends StatelessWidget {
  final FriendEntity friend;
  final Function(FriendEntity)? onInvite;
  final Function(FriendEntity)? onAdd;
  final Function(FriendEntity)? onViewProfile;

  final bool alreadyInvited;

  const _FriendTile({
    required this.friend,
    this.onInvite,
    this.onAdd,
    this.onViewProfile,
    this.alreadyInvited = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onlineColor = AppColors.online;
    final warningColor = AppColors.warning;
    final canInteract = !friend.isInLobby;
    final hasAvatar = friend.avatarUrl.trim().isNotEmpty;
    final initial = friend.username.trim().isEmpty
        ? '?'
        : friend.username.trim().characters.first.toUpperCase();

    return Material(
      color: isDark ? AppColors.surfaceDark : AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isDark ? AppColors.borderDark : AppColors.border,
          width: 2,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onViewProfile == null ? null : () => onViewProfile?.call(friend),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 360;
              final identity = Row(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.secondary,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDark
                                ? AppColors.borderDark
                                : AppColors.border,
                            width: 2,
                          ),
                        ),
                        child: hasAvatar
                            ? ClipOval(
                                child: Image.network(
                                  friend.avatarUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, e, st) => Center(
                                    child: Text(
                                      initial,
                                      style: const TextStyle(
                                        color: AppColors.white,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ),
                              )
                            : Center(
                                child: Text(
                                  initial,
                                  style: const TextStyle(
                                    color: AppColors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                      ),
                      Positioned(
                        right: -1,
                        bottom: -1,
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: onlineColor,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isDark
                                  ? AppColors.surfaceDark
                                  : AppColors.surface,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          friend.username,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                            color: isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(
                              friend.isInLobby
                                  ? AppIcons.busy
                                  : AppIcons.available,
                              size: 14,
                              color: friend.isInLobby
                                  ? warningColor
                                  : onlineColor,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                _getStatusText(friend),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: friend.isInLobby
                                      ? warningColor
                                      : (friend.isOnline
                                          ? onlineColor
                                          : (isDark
                                              ? AppColors.textSecondaryDark
                                              : AppColors.textSecondary)),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              );

              final actions = _FriendActions(
                friend: friend,
                alreadyInvited: alreadyInvited,
                onInvite: canInteract ? onInvite : null,
                onAdd: canInteract ? onAdd : null,
              );

              if (compact && canInteract) {
                return Column(
                  children: [
                    identity,
                    const SizedBox(height: AppSpacing.sm),
                    Align(alignment: Alignment.centerRight, child: actions),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: identity),
                  if (canInteract) ...[
                    const SizedBox(width: AppSpacing.sm),
                    actions,
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  String _getStatusText(FriendEntity friend) {
    if (friend.isInLobby) {
      return 'Đang ở phòng khác';
    }
    switch (friend.activityStatus) {
      case ActivityStatus.online:
        return 'Đang trực tuyến';
      case ActivityStatus.recentlyActive:
        return 'Hoạt động gần đây';
      case ActivityStatus.away:
        return 'Vắng mặt';
      case ActivityStatus.offline:
      default:
        return 'Ngoại tuyến';
    }
  }
}

class _FriendActions extends StatelessWidget {
  final FriendEntity friend;
  final Function(FriendEntity)? onInvite;
  final Function(FriendEntity)? onAdd;

  final bool alreadyInvited;

  const _FriendActions({
    required this.friend,
    this.onInvite,
    this.onAdd,
    this.alreadyInvited = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      alignment: WrapAlignment.end,
      children: [
        if (onAdd != null)
          _NeoMiniButton(
            label: 'Thêm',
            icon: AppIcons.addSimple,
            color: AppColors.secondary,
            onPressed: () => onAdd?.call(friend),
          ),
        if (onInvite != null)
          alreadyInvited
              ? Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xxs,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.surfaceElevatedDark
                        : AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDark
                          ? AppColors.borderDark
                          : AppColors.border,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        AppIcons.check,
                        size: 14,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Đã mời',
                        style: TextStyle(
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondary,
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                )
              : _NeoMiniButton(
                  label: 'Mời',
                  icon: AppIcons.send,
                  color: AppColors.primary,
                  onPressed: () => onInvite?.call(friend),
                ),
      ],
    );
  }
}

class _NeoMiniButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onPressed;

  const _NeoMiniButton({
    required this.label,
    required this.icon,
    required this.color,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xxs,
          ),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppColors.border,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withValues(alpha: 0.3),
                blurRadius: 0,
                offset: const Offset(2, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: AppColors.white),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyFriendsState extends StatelessWidget {
  const _EmptyFriendsState();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.secondary,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark ? AppColors.borderDark : AppColors.border,
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.black.withValues(alpha: 0.4),
                    blurRadius: 0,
                    offset: const Offset(4, 4),
                  ),
                ],
              ),
              child: const Icon(
                AppIcons.users,
                size: 48,
                color: AppColors.white,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Chưa có bạn bè',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 16,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Hãy kết bạn với những người chơi khác để mời họ tham gia phòng.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondary,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}