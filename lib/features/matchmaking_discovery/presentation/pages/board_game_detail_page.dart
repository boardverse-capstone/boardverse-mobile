import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/board_game_detail_entity.dart';
import '../../domain/entities/board_game_entity.dart';
import '../../domain/entities/game_play_configuration_entity.dart';
import '../cubit/matchmaking_cubit.dart';
import '../cubit/matchmaking_state.dart';
import '../widgets/cafe_card.dart';
import '../widgets/game_detail_header.dart';
import '../widgets/gps_warning_banner.dart';
import '../widgets/similar_games_carousel.dart';
import 'lobby_config_page.dart';
import '../../../booking_payment/presentation/pages/booking_summary_page.dart';

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
        body: MultiBlocListener(
          listeners: [
            // Listen play-navigation state để điều hướng sang Lobby / Solo Booking.
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
                        onPressed: () =>
                            widget.matchmakingCubit.loadGameDetail(
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

              // Cache last detail state để giữ UI khi đang resolve
              // play-navigation.
              if (state is MatchmakingGameDetail) {
                _lastDetailState = state;
              }

              if (state is MatchmakingGameDetail) {
                return _buildGameDetailView(context, state);
              }

              if (state is MatchmakingPlayNavigationResolving &&
                  _lastDetailState != null) {
                // Vẫn hiển thị UI cũ + overlay loading trong suốt.
                final lastDetail = _lastDetailState as MatchmakingGameDetail;
                return Stack(
                  children: [
                    _buildGameDetailView(context, lastDetail),
                    const Positioned.fill(
                      child: ColoredBox(
                        color: Color(0x33000000),
                        child: Center(child: CircularProgressIndicator()),
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

  /// Xử lý kết quả từ `play-navigation` — điều hướng sang Lobby (Group) hoặc
  /// Solo Booking.
  void _handlePlayNavigation(
      BuildContext context, MatchmakingPlayNavigationResolved state) {
    final nav = state.navigation;
    final gameId = nav.gameTemplateId;
    final gameName = nav.gameName ?? '';

    if (nav.isLobbyCreation) {
      // Group mode → tạo lobby như cũ. Chưa có cafeId ở bước này
      // (sẽ được chọn trong LobbyConfigPage).
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (ctx) => LobbyConfigPage(
            gameId: gameId,
            gameName: gameName,
            cafeId: '',
            cafeName: '',
            matchmakingCubit: widget.matchmakingCubit,
          ),
        ),
      );
    } else if (nav.isSoloBooking) {
      // Solo mode → đặt bàn trực tiếp.
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (ctx) => BookingSummaryPage(
            lobbyId: '', // Solo không có lobby
            cafeId: '',
            cafeName: '',
            gameId: gameId,
            gameName: gameName,
            scheduledTime:
                DateTime.now().add(const Duration(hours: 1)),
            seatCount: nav.roomConfiguration.defaultPlayerCount,
            memberIds: const [],
          ),
        ),
      );
    }
  }

  /// Card "Sẵn sàng chơi?" — bám sát logic PlayMode của backend.
  /// Hiển thị nút Chơi một mình / Chơi cùng nhóm.
  Widget _buildPlayActionCard(BuildContext context,
      MatchmakingGameDetail state) {
    final theme = Theme.of(context);
    final supportsSolo = state.game.minPlayers == 1;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bolt, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Sẵn sàng chơi?',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            supportsSolo
                ? 'Bạn có thể chơi một mình hoặc rủ thêm bạn bè.'
                : 'Game này cần tối thiểu ${state.game.minPlayers} người để bắt đầu.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.person),
                  label: const Text('Chơi một mình'),
                  onPressed: supportsSolo
                      ? () => widget.matchmakingCubit.resolvePlayNavigation(
                            gameId: state.game.id,
                            mode: PlayMode.solo,
                          )
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  icon: const Icon(Icons.groups),
                  label: const Text('Chơi cùng nhóm'),
                  onPressed: () =>
                      widget.matchmakingCubit.resolvePlayNavigation(
                    gameId: state.game.id,
                    mode: PlayMode.group,
                  ),
                ),
              ),
            ],
          ),
        ],
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
            child: _buildGameInfoSectionFromEntity(context, state.selectedGame!),
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
          child: _buildGameInfoSectionFromEntity(context, state.selectedGame),
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
    // Convert BoardGameDetailEntity to BoardGameEntity for widgets expecting BoardGameEntity
    final gameAsEntity = state.game.toBoardGameEntity();

    return CustomScrollView(
      slivers: [
        GameDetailHeader(game: gameAsEntity),
        SliverToBoxAdapter(
          child: _buildGameInfoSection(context, state.game),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildPlayActionCard(context, state),
          ),
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

  Widget _buildGameInfoSection(BuildContext context, BoardGameDetailEntity game) {
    final theme = Theme.of(context);
    final categoryName = game.categories.isNotEmpty
        ? game.categories.first.name
        : 'Board Game';

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
                  categoryName,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSecondaryContainer,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.star, color: Colors.amber.shade600, size: 20),
              const SizedBox(width: 4),
              Text(
                game.playTime > 0 ? '~${game.playTime} phút' : '-',
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
                label: '~${game.playTime} phút',
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
          if (game.components.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 20,
                    color: theme.colorScheme.outline,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Thông tin linh kiện trong hộp chưa được hệ thống cập nhật.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
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
                          game.components[index].componentName,
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

  /// Overload for BoardGameEntity (used in OutOfRadius/GpsDisabled states).
  Widget _buildGameInfoSectionFromEntity(BuildContext context, BoardGameEntity game) {
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
          if (game.components.isNotEmpty) ...[
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
