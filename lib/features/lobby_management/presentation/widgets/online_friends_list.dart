import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';
import '../../domain/entities/friend_entity.dart';

class OnlineFriendsList extends StatelessWidget {
  final List<FriendEntity> friends;
  final Function(FriendEntity)? onInvite;
  final Function(FriendEntity)? onAdd;
  final Function(FriendEntity)? onViewProfile;
  final ScrollController? controller;

  const OnlineFriendsList({
    super.key,
    required this.friends,
    this.onInvite,
    this.onAdd,
    this.onViewProfile,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final onlineFriends = friends.where((friend) => friend.isOnline).toList();

    if (onlineFriends.isEmpty) {
      return const _EmptyFriendsState();
    }

    return ListView.separated(
      controller: controller,
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      itemCount: onlineFriends.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.xs),
      itemBuilder: (context, index) {
        final friend = onlineFriends[index];
        return _FriendTile(
          friend: friend,
          onInvite: onInvite,
          onAdd: onAdd,
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

  const _FriendTile({
    required this.friend,
    this.onInvite,
    this.onAdd,
    this.onViewProfile,
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
    final initial = friend.name.trim().isEmpty
        ? '?'
        : friend.name.trim().characters.first.toUpperCase();

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
                          friend.name,
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
                                friend.isInLobby
                                    ? 'Đang ở phòng khác'
                                    : 'Đang trực tuyến',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: friend.isInLobby
                                      ? warningColor
                                      : onlineColor,
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
}

class _FriendActions extends StatelessWidget {
  final FriendEntity friend;
  final Function(FriendEntity)? onInvite;
  final Function(FriendEntity)? onAdd;

  const _FriendActions({required this.friend, this.onInvite, this.onAdd});

  @override
  Widget build(BuildContext context) {
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
          OutlinedButton.icon(
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
              'Chưa có bạn bè trực tuyến',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Khi bạn bè online, bạn có thể mời họ tham gia phòng tại đây.',
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
