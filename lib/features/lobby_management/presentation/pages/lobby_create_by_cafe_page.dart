import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/theme/theme.dart';
import '../../../matchmaking_discovery/domain/entities/board_game_entity.dart';
import '../../../matchmaking_discovery/domain/entities/game_category_entity.dart';
import '../../../matchmaking_discovery/presentation/cubit/matchmaking_cubit.dart';
import '../../../matchmaking_discovery/presentation/cubit/matchmaking_state.dart';
import '../../../matchmaking_discovery/presentation/pages/lobby_cafe_selection_page.dart';

/// Flow "Chọn quán trước":
/// 1. Player chọn thể loại game (Strategy / Party / Casual / ...)
/// 2. Chọn 1 game đại diện trong category đó
/// 3. → Push [LobbyCafeSelectionPage] (flow cũ) với game đã chọn làm proxy
///
/// Lý do cần game "đại diện": backend `/api/cafes/nearby/me` yêu cầu
/// `gameTemplateId` bắt buộc — không có endpoint list cafe chung. Player có
/// thể đổi game thật tại quán khi nhận bàn.
class LobbyCreateByCafePage extends StatefulWidget {
  const LobbyCreateByCafePage({super.key});

  @override
  State<LobbyCreateByCafePage> createState() => _LobbyCreateByCafePageState();
}

class _LobbyCreateByCafePageState extends State<LobbyCreateByCafePage> {
  late final MatchmakingCubit _matchmakingCubit;
  String? _selectedCategoryId;
  bool _hasLoadedInitial = false;

  @override
  void initState() {
    super.initState();
    _matchmakingCubit = context.read<MatchmakingCubit>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _hasLoadedInitial) return;
      _hasLoadedInitial = true;
      _loadCategoriesAndAll();
    });
  }

  void _loadCategoriesAndAll() {
    // Đảm bảo categories được load (loadCategories chỉ update state nếu đã
    // ở MatchmakingSearchResults, nên trigger searchGames trước).
    final state = _matchmakingCubit.state;
    if (state is! MatchmakingSearchResults) {
      _matchmakingCubit.searchGames();
    } else {
      _matchmakingCubit.loadCategories();
    }
  }

  void _onCategorySelected(GameCategoryEntity category) {
    setState(() => _selectedCategoryId = category.id);
    _matchmakingCubit.searchWithFilterPaged(
      categoryIds: [category.id],
      pageNumber: 1,
      pageSize: 20,
    );
  }

  Future<void> _pickRandomGame(List<BoardGameEntity> games) async {
    if (games.isEmpty) return;
    final random = games[DateTime.now().millisecondsSinceEpoch % games.length];
    if (!mounted) return;
    await _openCafeSelection(random);
  }

  Future<void> _openCafeSelection(BoardGameEntity game) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LobbyCafeSelectionPage(
          game: game,
          matchmakingCubit: _matchmakingCubit,
        ),
      ),
    );
    if (mounted) Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tạo lobby tại quán'),
        centerTitle: false,
      ),
      body: BlocProvider.value(
        value: _matchmakingCubit,
        child: BlocBuilder<MatchmakingCubit, MatchmakingState>(
          builder: (context, state) {
            final categories = state is MatchmakingSearchResults
                ? state.categories
                : <GameCategoryEntity>[];
            final games = state is MatchmakingSearchResults
                ? state.games
                : <BoardGameEntity>[];

            return ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                AppSpacing.lg,
              ),
              children: [
                _IntroBanner(theme: theme),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Chọn thể loại',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                if (state is MatchmakingLoading && categories.isEmpty)
                  const Center(child: CircularProgressIndicator())
                else if (categories.isEmpty)
                  _ErrorBox(
                    message:
                        'Không tải được danh mục game. Kéo xuống để thử lại.',
                    onRetry: _loadCategoriesAndAll,
                  )
                else
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      for (final c in categories)
                        ChoiceChip(
                          label: Text(c.name),
                          selected: _selectedCategoryId == c.id,
                          onSelected: (_) => _onCategorySelected(c),
                        ),
                      ChoiceChip(
                        label: const Text('Tất cả'),
                        selected: _selectedCategoryId == null,
                        onSelected: (_) {
                          setState(() => _selectedCategoryId = null);
                          _matchmakingCubit.searchGames();
                        },
                      ),
                    ],
                  ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _selectedCategoryId == null
                          ? 'Game phổ biến'
                          : 'Game trong thể loại đã chọn',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (games.isNotEmpty)
                      TextButton.icon(
                        onPressed: () => _pickRandomGame(games),
                        icon: const Icon(Icons.shuffle),
                        label: const Text('Ngẫu nhiên'),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                if (state is MatchmakingLoading && games.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (state is MatchmakingFailure && games.isEmpty)
                  _ErrorBox(
                    message: state.message,
                    onRetry: _loadCategoriesAndAll,
                  )
                else if (games.isEmpty)
                  _ErrorBox(
                    message: 'Chưa có game nào trong thể loại này.',
                    onRetry: _loadCategoriesAndAll,
                  )
                else
                  ...games.map(
                    (g) => _GamePickTile(
                      game: g,
                      onTap: () => _openCafeSelection(g),
                    ),
                  ),
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: theme.colorScheme.secondary,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'Chọn 1 game đại diện để tìm quán có sẵn hộp. '
                          'Bạn có thể đổi sang game khác khi tới quán nếu quán '
                          'có nhiều loại game.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _IntroBanner extends StatelessWidget {
  final ThemeData theme;
  const _IntroBanner({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.local_cafe,
            color: theme.colorScheme.onPrimaryContainer,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Chọn quán trước, game sau',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Phù hợp khi bạn đã biết quán cafe mình muốn tới.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GamePickTile extends StatelessWidget {
  final BoardGameEntity game;
  final VoidCallback onTap;
  const _GamePickTile({required this.game, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: 48,
            height: 48,
            child: game.imageUrl.isNotEmpty
                ? Image.network(
                    game.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => _Placeholder(theme: theme),
                  )
                : _Placeholder(theme: theme),
          ),
        ),
        title: Text(game.name),
        subtitle: Text(
          '${game.minPlayers}–${game.maxPlayers} người • ${game.estimatedMinutes} phút',
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  final ThemeData theme;
  const _Placeholder({required this.theme});
  @override
  Widget build(BuildContext context) {
    return Container(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Icon(Icons.casino, color: theme.colorScheme.outline),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorBox({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: theme.colorScheme.onErrorContainer),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onErrorContainer,
              ),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Thử lại')),
        ],
      ),
    );
  }
}
