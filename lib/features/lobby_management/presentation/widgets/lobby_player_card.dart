import 'package:flutter/material.dart';
import '../../domain/entities/lobby_entity.dart';

class LobbyPlayerCard extends StatelessWidget {
  final LobbyPlayer player;
  final bool isCurrentUser;
  final VoidCallback? onTap;

  const LobbyPlayerCard({
    super.key,
    required this.player,
    this.isCurrentUser = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isCurrentUser
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: isCurrentUser
              ? Border.all(color: theme.colorScheme.primary, width: 2)
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundImage: NetworkImage(player.avatarUrl),
                  onBackgroundImageError: (_, _) {},
                  child: player.avatarUrl.isEmpty
                      ? Text(player.name[0].toUpperCase())
                      : null,
                ),
                if (player.isHost)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade600,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.star,
                        size: 12,
                        color: Colors.white,
                      ),
                    ),
                  ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: player.isReady ? Colors.green : Colors.grey,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              player.name,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (player.isHost)
              Text(
                'Chủ phòng',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: Colors.amber.shade700,
                ),
              )
            else if (player.isReady)
              Text(
                'Sẵn sàng',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: Colors.green,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class LobbyPlayerGrid extends StatelessWidget {
  final List<LobbyPlayer> players;
  final int maxSlots;
  final String? currentUserId;
  final Function(LobbyPlayer)? onPlayerTap;

  const LobbyPlayerGrid({
    super.key,
    required this.players,
    required this.maxSlots,
    this.currentUserId,
    this.onPlayerTap,
  });

  @override
  Widget build(BuildContext context) {
    final emptySlots = maxSlots - players.length;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 0.8,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: players.length + emptySlots,
      itemBuilder: (context, index) {
        if (index < players.length) {
          final player = players[index];
          return LobbyPlayerCard(
            player: player,
            isCurrentUser: player.id == currentUserId,
            onTap: () => onPlayerTap?.call(player),
          );
        } else {
          return _EmptySlot();
        }
      },
    );
  }
}

class _EmptySlot extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.3),
          style: BorderStyle.solid,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.person_add,
          color: theme.colorScheme.outline.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}
