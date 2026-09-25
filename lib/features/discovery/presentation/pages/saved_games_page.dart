import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/neo_brutalism_theme.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/error_state_widget.dart';
import '../cubit/saved_games_cubit.dart';
import '../cubit/saved_games_state.dart';

/// Trang danh sách game đã lưu.
class SavedGamesPage extends StatelessWidget {
  const SavedGamesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<SavedGamesCubit>()..loadSavedGames(),
      child: const _SavedGamesPageContent(),
    );
  }
}

class _SavedGamesPageContent extends StatelessWidget {
  const _SavedGamesPageContent();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      appBar: AppBar(
        title: const Text('Game đã lưu'),
        centerTitle: true,
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surface,
        elevation: 0,
      ),
      body: BlocBuilder<SavedGamesCubit, SavedGamesState>(
        builder: (context, state) {
          if (state is SavedGamesInitial ||
              state is SavedGamesLoadingFromCache) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is SavedGamesError && state.games == null) {
            return ErrorStateWidget(
              message: state.message,
              onRetry: () => context.read<SavedGamesCubit>().loadSavedGames(),
            );
          }

          final games = state is SavedGamesLoaded
              ? state.games
              : state is SavedGamesRefreshing
                  ? state.games
                  : state is SavedGamesError
                      ? state.games ?? []
                      : [];

          if (games.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.favorite_border,
              title: 'Chưa có game nào',
              message:
                  'Lưu game bạn thích bằng cách nhấn icon trái tim trên game card',
            );
          }

          return RefreshIndicator(
            onRefresh: () => context.read<SavedGamesCubit>().refresh(),
            child: GridView.builder(
              padding: const EdgeInsets.all(AppSpacing.md),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: AppSpacing.md,
                crossAxisSpacing: AppSpacing.md,
                childAspectRatio: 0.75,
              ),
              itemCount: games.length,
              itemBuilder: (context, i) {
                final game = games[i];
                return _SavedGameCard(
                  game: game,
                  onTap: () {},
                  onRemove: () {
                    context.read<SavedGamesCubit>().toggleSave(
                          game.gameTemplateId,
                        );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _SavedGameCard extends StatelessWidget {
  final dynamic game; // SavedBoardGameEntity
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _SavedGameCard({
    required this.game,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: NeoBrutalismTheme.autoBox(
          context,
          backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surface,
          borderRadius: 16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(16)),
                    child: game.thumbnailUrl != null
                        ? Image.network(
                            game.thumbnailUrl!,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            height: double.infinity,
                            errorBuilder: (_, __, ___) =>
                                _placeholder(isDark),
                          )
                        : _placeholder(isDark),
                  ),
                  // Remove button
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: onRemove,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.favorite,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Info
            Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    game.gameName,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (game.weight != null) ...[
                        _smallBadge('W: ${game.weight!.toStringAsFixed(1)}'),
                        const SizedBox(width: 4),
                      ],
                      if (game.playTime != null)
                        _smallBadge('${game.playTime} phút'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder(bool isDark) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: isDark
          ? AppColors.surfaceDark.withValues(alpha: 0.5)
          : AppColors.background,
      child: Icon(
        Icons.sports_esports,
        color: Colors.grey.shade300,
        size: 40,
      ),
    );
  }

  Widget _smallBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
