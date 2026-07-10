import 'package:flutter/material.dart';
import '../../domain/entities/friend_entity.dart';

class OnlineFriendsList extends StatelessWidget {
  final List<FriendEntity> friends;
  final Function(FriendEntity)? onInvite;
  final Function(FriendEntity)? onAdd;
  final Function(FriendEntity)? onViewProfile;

  const OnlineFriendsList({
    super.key,
    required this.friends,
    this.onInvite,
    this.onAdd,
    this.onViewProfile,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onlineFriends = friends.where((f) => f.isOnline).toList();

    if (onlineFriends.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.people_outline,
                size: 48,
                color: theme.colorScheme.outline,
              ),
              const SizedBox(height: 8),
              Text(
                'Không có bạn bè trực tuyến',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      itemCount: onlineFriends.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final friend = onlineFriends[index];
        return ListTile(
          leading: Stack(
            children: [
              CircleAvatar(
                backgroundImage: NetworkImage(friend.avatarUrl),
                onBackgroundImageError: (_, _) {},
                child: friend.avatarUrl.isEmpty
                    ? Text(friend.name[0].toUpperCase())
                    : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: friend.isOnline ? Colors.green : Colors.grey,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),
          title: Text(friend.name),
          subtitle: friend.isInLobby
              ? Text(
                  'Đang ở phòng khác',
                  style: TextStyle(color: Colors.orange.shade700),
                )
              : null,
          trailing: friend.isInLobby
              ? null
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (onAdd != null)
                      FilledButton.tonal(
                        onPressed: () => onAdd?.call(friend),
                        child: const Text('Thêm'),
                      ),
                    if (onInvite != null && onAdd != null)
                      const SizedBox(width: 8),
                    if (onInvite != null)
                      OutlinedButton(
                        onPressed: () => onInvite?.call(friend),
                        child: const Text('Mời'),
                      ),
                  ],
                ),
          onTap: () => onViewProfile?.call(friend),
        );
      },
    );
  }
}
