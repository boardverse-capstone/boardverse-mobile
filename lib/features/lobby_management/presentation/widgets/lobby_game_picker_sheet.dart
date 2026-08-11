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
                  borderRadius: AppRadius.radiusXxsAll,
                ),
              ),
            ),
            Text(
              'Chọn game',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.sm),
            if (games.isEmpty)
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(
                    3,
                    (_) => const Padding(
                      padding: EdgeInsets.only(bottom: AppSpacing.sm),
                      child: _GamePickerTileSkeleton(),
                    ),
                  ),
                ),
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
          borderRadius: AppRadius.radiusSmAll,
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

/// Skeleton tile cho game picker khi đang load danh sách game.
class _GamePickerTileSkeleton extends StatelessWidget {
  const _GamePickerTileSkeleton();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgBase = isDark ? AppColors.surfaceElevatedDark : AppColors.surface;

    return AppShimmer.shimmer(
      context: context,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: bgBase,
          borderRadius: AppRadius.radiusMdAll,
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.border,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Container(
                    width: 140,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
