import 'package:flutter/material.dart';

import 'package:boardverse_mobile/core/theme/theme.dart';
import 'package:boardverse_mobile/features/friend_management/domain/entities/friend_entity.dart';

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
  ///
  /// Mặc định `false` — chỉ hiển thị khi caller chủ động bật (một số
  /// màn hình dev/diagnostic cần nút này, ví dụ "giả lập thêm bạn vào phòng").
  /// Trong lobby thực tế chỉ dùng nút "Mời", nên không truyền `onAdd` là
  /// nút này tự ẩn.
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
    // Hiển thị TẤT CẢ bạn bè - không lọc online
    // Invitation sẽ được gửi dù friend online hay offline
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

  /// `true` nếu friend này đã được mời thành công trong session —
  /// tile sẽ disable nút "Mời" và đổi thành "Đã mời" + icon check.
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
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final onlineColor = theme.brightness == Brightness.dark
        ? AppColorsDark.online
        : AppColors.online;
    final warningColor = theme.brightness == Brightness.dark
        ? AppColorsDark.warning
        : AppColors.warningDark;
    final canInteract = !friend.isInLobby;
    final hasAvatar = friend.avatarUrl.trim().isNotEmpty;
    final initial = friend.username.trim().isEmpty
        ? '?'
        : friend.username.trim().characters.first.toUpperCase();

    return Material(
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.radiusMdAll,
        side: BorderSide(color: colors.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onViewProfile == null ? null : () => onViewProfile?.call(friend),
        child: Padding(
          padding: AppSpacing.listItemPadding,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 360;
              final identity = Row(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      CircleAvatar(
                        radius: AppSpacing.xl,
                        backgroundColor: colors.secondaryContainer,
                        foregroundColor: colors.onSecondaryContainer,
                        backgroundImage: hasAvatar
                            ? NetworkImage(friend.avatarUrl)
                            : null,
                        onBackgroundImageError: hasAvatar ? (_, _) {} : null,
                        child: hasAvatar
                            ? null
                            : Text(
                                initial,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: colors.onSecondaryContainer,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                      Positioned(
                        right: -1,
                        bottom: -1,
                        child: Container(
                          width: AppSpacing.md,
                          height: AppSpacing.md,
                          decoration: BoxDecoration(
                            color: onlineColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: colors.surface, width: 2),
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
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Row(
                          children: [
                            Icon(
                              friend.isInLobby
                                  ? AppIcons.busy
                                  : AppIcons.available,
                              size: AppIcons.sm,
                              color: friend.isInLobby
                                  ? warningColor
                                  : onlineColor,
                            ),
                            const SizedBox(width: AppSpacing.xxs),
                            Flexible(
                              child: Text(
                                _getStatusText(friend),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: friend.isInLobby
                                      ? warningColor
                                      : (friend.isOnline ? onlineColor : colors.onSurfaceVariant),
                                  fontWeight: FontWeight.w500,
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

  /// `true` nếu friend đã được mời thành công — đổi nút "Mời" thành
  /// "Đã mời" + icon check + disable để tránh mời trùng.
  final bool alreadyInvited;

  const _FriendActions({
    required this.friend,
    this.onInvite,
    this.onAdd,
    this.alreadyInvited = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      alignment: WrapAlignment.end,
      children: [
        if (onAdd != null)
          FilledButton.tonalIcon(
            onPressed: () => onAdd?.call(friend),
            icon: const Icon(AppIcons.addSimple, size: AppIcons.sm),
            label: const Text('Thêm'),
          ),
        if (onInvite != null)
          alreadyInvited
              ? OutlinedButton.icon(
                  // Disabled — chỉ hiển thị trạng thái "Đã mời".
                  onPressed: null,
                  icon: Icon(
                    AppIcons.check,
                    size: AppIcons.sm,
                    color: colors.onSurfaceVariant,
                  ),
                  label: const Text('Đã mời'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colors.onSurfaceVariant,
                    side: BorderSide(color: colors.outlineVariant),
                  ),
                )
              : OutlinedButton.icon(
                  onPressed: () => onInvite?.call(friend),
                  icon: const Icon(AppIcons.send, size: AppIcons.sm),
                  label: const Text('Mời'),
                ),
      ],
    );
  }
}

class _EmptyFriendsState extends StatelessWidget {
  const _EmptyFriendsState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: colors.secondaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                AppIcons.users,
                size: AppIcons.xl,
                color: colors.onSecondaryContainer,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Chưa có bạn bè',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Hãy kết bạn với những người chơi khác để mời họ tham gia phòng.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
