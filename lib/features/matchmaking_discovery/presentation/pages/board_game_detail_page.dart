import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/matchmaking_cubit.dart';
import '../cubit/matchmaking_state.dart';
import '../widgets/cafe_card.dart';
import '../widgets/game_detail_header.dart';
import '../widgets/gps_warning_banner.dart';
import '../widgets/similar_games_carousel.dart';
import 'lobby_config_page.dart';

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
  @override
  void initState() {
    super.initState();
    widget.matchmakingCubit.loadGameDetail(gameId: widget.gameId);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: widget.matchmakingCubit,
      child: Scaffold(
        body: BlocBuilder<MatchmakingCubit, MatchmakingState>(
          builder: (context, state) {
            if (state is MatchmakingLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is MatchmakingFailure) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(height: 16),
                    Text(state.message),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () => widget.matchmakingCubit.loadGameDetail(
                        gameId: widget.gameId,
                      ),
                      child: const Text('Thử lại'),
                    ),
                  ],
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
              return _buildGameDetailView(context, state);
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildGpsDisabledView(BuildContext context, MatchmakingGpsDisabled state) {
    return CustomScrollView(
      slivers: [
        if (state.selectedGame != null)
          GameDetailHeader(game: state.selectedGame!),
        SliverToBoxAdapter(
          child: GpsWarningBanner(
            onEnableGps: () {
              widget.matchmakingCubit.enableGpsAndReload(gameId: widget.gameId);
            },
            onEnterManually: () {
              _showManualLocationDialog(context);
            },
          ),
        ),
        if (state.selectedGame != null)
          SliverToBoxAdapter(
            child: _buildGameInfoSection(context, state.selectedGame!),
          ),
      ],
    );
  }

  Widget _buildOutOfRadiusView(
      BuildContext context, MatchmakingOutOfRadius state) {
    return CustomScrollView(
      slivers: [
        GameDetailHeader(game: state.selectedGame),
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.location_off,
                  size: 48,
                  color: Colors.red.shade400,
                ),
                const SizedBox(height: 8),
                Text(
                  'Không có quán nào trong bán kính 15km',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
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
          child: _buildGameInfoSection(context, state.selectedGame),
        ),
        if (state.similarGames.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 16),
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
      BuildContext context, MatchmakingGameDetail state) {
    return CustomScrollView(
      slivers: [
        GameDetailHeader(game: state.game),
        SliverToBoxAdapter(
          child: _buildGameInfoSection(context, state.game),
        ),
        const SliverToBoxAdapter(
          child: Divider(height: 32),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Quán cafe gần bạn',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
        ),
        if (state.nearbyCafes.isEmpty)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('Không có quán nào có game này gần bạn.'),
            ),
          )
        else
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final cafe = state.nearbyCafes[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: CafeCard(
                    cafe: cafe,
                    onBookingTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LobbyConfigPage(
                          gameId: widget.gameId,
                          gameName: state.game.name,
                          cafeId: cafe.id,
                          cafeName: cafe.name,
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
          child: SizedBox(height: 100),
        ),
      ],
    );
  }

  Widget _buildGameInfoSection(BuildContext context, game) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  game.category,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSecondaryContainer,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.star, color: Colors.amber.shade600, size: 20),
              const SizedBox(width: 4),
              Text(
                game.rating.toStringAsFixed(1),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Mô tả',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            game.description,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _InfoChip(
                icon: Icons.people,
                label: '${game.minPlayers}-${game.maxPlayers} người',
              ),
              const SizedBox(width: 8),
              _InfoChip(
                icon: Icons.timer,
                label: '~${game.estimatedMinutes} phút',
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Linh kiện trong hộp',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: game.components.length,
            itemBuilder: (context, index) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_box,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        game.components[index],
                        style: theme.textTheme.bodySmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
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
            border: OutlineInputBorder(),
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

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
