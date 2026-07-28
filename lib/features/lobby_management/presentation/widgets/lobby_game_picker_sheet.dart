import 'package:flutter/material.dart';

import '../../../../../core/theme/theme.dart';
import '../../../matchmaking_discovery/domain/entities/board_game_entity.dart';

/// Bottom sheet cho phép chọn game.
class LobbyGamePickerSheet extends StatelessWidget {
  final List<BoardGameEntity> games;

  const LobbyGamePickerSheet({super.key, required this.games});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              'Chọn game',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.sm),
            if (games.isEmpty)
              const Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: Center(child: CircularProgressIndicator()),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: games.length,
                  itemBuilder: (context, index) {
                    final game = games[index];
                    return _GameListTile(game: game, theme: theme);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _GameListTile extends StatelessWidget {
  final BoardGameEntity game;
  final ThemeData theme;

  const _GameListTile({required this.game, required this.theme});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            game.name.isNotEmpty ? game.name[0] : '?',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      title: Text(game.name),
      subtitle: Text(
        '${game.category} • ${game.minPlayers}-${game.maxPlayers} người',
        style: theme.textTheme.bodySmall,
      ),
      onTap: () => Navigator.pop(context, game),
    );
  }
}
