import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/navigation/lobby_suggestion_signal.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/alternative_game_suggestion_entity.dart';
import '../../domain/entities/board_game_entity.dart';
import '../../domain/entities/game_play_configuration_entity.dart';
import '../cubit/matchmaking_cubit.dart';
import '../cubit/matchmaking_state.dart';
import '../pages/cafe_detail_page.dart';
import '../pages/lobby_cafe_selection_page.dart';
import '../widgets/cafe_card.dart';
import '../widgets/game_detail_header.dart';
import '../widgets/game_info_section.dart';
import '../widgets/gps_warning_banner.dart';
import '../widgets/similar_games_carousel.dart';

class BoardGameDetailPage extends StatefulWidget {
  final String gameId;
  final MatchmakingCubit matchmakingCubit;

  const BoardGameDetailPage({
    super.key,
    required this.gameId,
    required this.matchmakingCubit,
  });

  @override
  State<BoardGameDetailPage> createState() => _BoardGameDetailPageState();
}

class _BoardGameDetailPageState extends State<BoardGameDetailPage> {
  MatchmakingState? _lastDetailState;
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    widget.matchmakingCubit.loadGameDetail(gameId: widget.gameId);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: widget.matchmakingCubit,
      child: Scaffold(
        body: MultiBlocListener(
          listeners: [
            BlocListener<MatchmakingCubit, MatchmakingState>(
              listenWhen: (prev, curr) =>
                  curr is MatchmakingPlayNavigationResolved ||
                  curr is MatchmakingFailure,
              listener: (context, state) {
                if (state is MatchmakingPlayNavigationResolved) {
                  _handlePlayNavigation(context, state);
                }
              },
            ),
          ],
          child: BlocBuilder<MatchmakingCubit, MatchmakingState>(
            builder: (context, state) {
              if (state is MatchmakingLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state is MatchmakingFailure) {
                return _ErrorRetryView(
                  message: state.message,
                  onRetry: () => widget.matchmakingCubit.loadGameDetail(
                    gameId: widget.gameId,
                  ),
                );
              }
              if (state is MatchmakingGpsDisabled) {
                return _buildGpsDisabledView(context, state);
              }
              if (state is MatchmakingOutOfRadius) {
                return _buildOutOfRadiusView(context, state);
              }

              if (state is MatchmakingGameDetail) {
                _lastDetailState = state;
                return _buildGameDetailView(context, state);
              }

              if (state is MatchmakingPlayNavigationResolving &&
                  _lastDetailState != null) {
                final lastDetail =
                    _lastDetailState as MatchmakingGameDetail;
                return Stack(
                  children: [
                    _buildGameDetailView(context, lastDetail),
                    Positioned.fill(
                      child: ColoredBox(
                        color: AppColors.black.withValues(alpha: 0.3),
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                    ),
                  ],
                );
              }

              if (state is MatchmakingPlayNavigationResolving) {
                return const Center(child: CircularProgressIndicator());
              }

              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }

  /// Xử lý kết quả từ `play-navigation` — điều hướng sang Lobby screen
  /// (group) hoặc Solo Booking (đặt bàn trực tiếp).
  void _handlePlayNavigation(
    BuildContext context,
    MatchmakingPlayNavigationResolved state,
  ) {
    final nav = state.navigation;
    final gameId = nav.gameTemplateId;
    final gameName = nav.gameName ?? '';

    final current = widget.matchmakingCubit.state;
    BoardGameEntity? gameEntity;
    if (current is MatchmakingGameDetail) {
      gameEntity = current.game.toBoardGameEntity();
    }
    gameEntity ??= BoardGameEntity(
      id: gameId,
      name: gameName.isEmpty ? 'Game' : gameName,
      description: '',
      imageUrl: '',
      minPlayers: nav.roomConfiguration.minPlayers,
      maxPlayers: nav.roomConfiguration.maxPlayers,
      estimatedMinutes: 0,
      category: '',
      components: const [],
      mechanics: const [],
      rating: 0,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LobbyCafeSelectionPage(
          game: gameEntity!,
          matchmakingCubit: widget.matchmakingCubit,
        ),
      ),
    );

    if (nav.isLobbyCreation) {
      LobbySuggestionSignal.instance.request(gameEntity);
    }
  }

  Widget _buildGpsDisabledView(
    BuildContext context,
    MatchmakingGpsDisabled state,
  ) {
    return CustomScrollView(
      slivers: [
        if (state.selectedGame != null)
          GameDetailHeader(game: state.selectedGame!),
        SliverToBoxAdapter(
          child: GpsWarningBanner(
            onEnableGps: () {
              widget.matchmakingCubit.enableGpsAndReload(
                gameId: widget.gameId,
              );
            },
            onEnterManually: () => _showManualLocationDialog(context),
          ),
        ),
        if (state.selectedGame != null)
          SliverToBoxAdapter(
            child: GameInfoSection.fromEntity(state.selectedGame!),
          ),
      ],
    );
  }

  Widget _buildOutOfRadiusView(
    BuildContext context,
    MatchmakingOutOfRadius state,
  ) {
    return CustomScrollView(
      slivers: [
        GameDetailHeader(game: state.selectedGame),
        SliverToBoxAdapter(
          child: Container(
            margin: AppSpacing.paddingAllMd,
            padding: AppSpacing.paddingAllMd,
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.08),
              borderRadius: AppRadius.radiusSmAll,
              border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.location_off,
                  size: AppSpacing.huge,
                  color: AppColors.error,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Không có quán nào trong bán kính 15km',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  'Dưới đây là các game tương tự mà bạn có thể thích:',
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: GameInfoSection.fromEntity(state.selectedGame),
        ),
        if (state.similarGames.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: AppSpacing.md),
              child: SimilarGamesCarousel(
                games: state.similarGames,
                onGameTap: (game) => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BoardGameDetailPage(
                      gameId: game.id,
                      matchmakingCubit: widget.matchmakingCubit,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildGameDetailView(
    BuildContext context,
    MatchmakingGameDetail state,
  ) {
    final gameAsEntity = state.game.toBoardGameEntity();

    final isResolving = widget.matchmakingCubit.state
        is MatchmakingPlayNavigationResolving;
    final supportsSolo = state.game.minPlayers == 1;

    return Stack(
      children: [
        CustomScrollView(
          controller: _scrollController,
          slivers: [
            GameDetailHeader(game: gameAsEntity),
            SliverToBoxAdapter(
              child: GameInfoSection.fromDetail(state.game),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: AppSpacing.md),
                child: Padding(
                  padding: AppSpacing.paddingHorizontalMd,
                  child: Text(
                    'Quán cafe gần bạn',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ),
            ),
            if (state.nearbyCafes.isEmpty)
              SliverToBoxAdapter(
                child: _buildNearbyEmptyState(
                  context,
                  emptyMessage: state.emptyResultMessage,
                  alternatives: state.alternativeSuggestions,
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final cafe = state.nearbyCafes[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.xs,
                      ),
                      child: CafeCard(
                        cafe: cafe,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CafeDetailPage(
                              cafeId: cafe.id,
                              selectedGame: gameAsEntity,
                              matchmakingCubit: widget.matchmakingCubit,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                  childCount: state.nearbyCafes.length,
                ),
              ),
            const SliverToBoxAdapter(
              child: SizedBox(height: AppSpacing.huge + AppSpacing.lg),
            ),
          ],
        ),
        _buildStickyBottomCta(
          context: context,
          state: state,
          isResolving: isResolving,
          supportsSolo: supportsSolo,
        ),
      ],
    );
  }

  Widget _buildStickyBottomCta({
    required BuildContext context,
    required MatchmakingGameDetail state,
    required bool isResolving,
    required bool supportsSolo,
  }) {
    final theme = Theme.of(context);

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              if (supportsSolo) ...[
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.person_rounded, size: 20),
                    label: const Text('Một mình'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                      shape: RoundedRectangleBorder(
                        borderRadius: AppRadius.radiusMdAll,
                      ),
                      side: BorderSide(color: theme.colorScheme.outlineVariant),
                    ),
                    onPressed: isResolving
                        ? null
                        : () => widget.matchmakingCubit.resolvePlayNavigation(
                              gameId: state.game.id,
                              mode: PlayMode.solo,
                            ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
              ],
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  icon: Icon(
                    supportsSolo ? Icons.groups_rounded : Icons.calendar_today_rounded,
                    size: 20,
                  ),
                  label: Text(supportsSolo ? 'Tạo lobby' : 'Đặt bàn'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.radiusMdAll,
                    ),
                  ),
                  onPressed: isResolving
                      ? null
                      : () => widget.matchmakingCubit.resolvePlayNavigation(
                            gameId: state.game.id,
                            mode: PlayMode.group,
                          ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNearbyEmptyState(
    BuildContext context, {
    required String? emptyMessage,
    required List<AlternativeGameSuggestionEntity> alternatives,
  }) {
    final theme = Theme.of(context);
    final message = emptyMessage ??
        'Không có quán nào có game này gần bạn. Hãy thử chọn game khác.';
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: AppSpacing.paddingAllMd,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest
                  .withValues(alpha: 0.5),
              borderRadius: AppRadius.radiusSmAll,
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.location_off,
                  color: theme.colorScheme.outline,
                  size: AppSpacing.xl,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    message,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (alternatives.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            SimilarGamesCarousel(
              games: alternatives
                  .map<BoardGameEntity>((s) => s.toBoardGameEntity())
                  .toList(),
              onGameTap: (game) => Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => BoardGameDetailPage(
                    gameId: game.id,
                    matchmakingCubit: widget.matchmakingCubit,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showManualLocationDialog(BuildContext context) {
    final districtController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nhập vị trí thủ công'),
        content: TextField(
          controller: districtController,
          decoration: const InputDecoration(
            labelText: 'Quận/Huyện',
            hintText: 'Ví dụ: Quận 1',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              widget.matchmakingCubit.loadCafesWithManualLocation(
                gameId: widget.gameId,
                district: districtController.text,
              );
            },
            child: const Text('Tìm kiếm'),
          ),
        ],
      ),
    );
  }
}

class _ErrorRetryView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorRetryView({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: AppSpacing.paddingAllXl,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off,
              size: AppSpacing.huge + AppSpacing.xs,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}