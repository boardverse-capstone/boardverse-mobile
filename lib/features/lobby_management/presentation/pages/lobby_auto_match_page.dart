import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';

import '../../../../../core/theme/theme.dart';
import '../../data/realtime/lobby_realtime_service.dart';
import '../../domain/entities/lobby_entity.dart';
import '../cubit/lobby_cubit.dart';
import '../cubit/lobby_search_cubit.dart';
import '../cubit/lobby_state.dart';
import 'lobby_page.dart';
import 'lobby_preview_page.dart';

/// Flow "Auto-match (random lobby)":
/// - Không cần chọn game/quán trước
/// - Hệ thống tự list các lobby công khai đang mở gần player
/// - Player chọn lobby → join, hoặc nhấn "Random" để hệ thống tự ghép vào
///   lobby có slot còn trống và gần nhất.
///
/// Backend support:
/// - `GET /api/v1/lobbies/discoverable?limit=50`
/// - SignalR `SubscribeNearbyLobbies` (tự động refresh khi có lobby mới)
class LobbyAutoMatchPage extends StatefulWidget {
  const LobbyAutoMatchPage({super.key});

  @override
  State<LobbyAutoMatchPage> createState() => _LobbyAutoMatchPageState();
}

class _LobbyAutoMatchPageState extends State<LobbyAutoMatchPage> {
  late final LobbySearchCubit _searchCubit;
  late final LobbyCubit _lobbyCubit;
  late final LobbyRealtimeService _realtime;
  late final DateFormat _timeFormatter;

  bool _hasLoadedInitial = false;

  @override
  void initState() {
    super.initState();
    _searchCubit = context.read<LobbySearchCubit>();
    _lobbyCubit = context.read<LobbyCubit>();
    _realtime = GetIt.instance<LobbyRealtimeService>();
    _timeFormatter = DateFormat('HH:mm');

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || _hasLoadedInitial) return;
      _hasLoadedInitial = true;
      await _ensureRealtime();
      if (!mounted) return;
      _searchCubit.loadDiscoverable(limit: 50);
    });
  }

  Future<void> _ensureRealtime() async {
    try {
      await _realtime.connect();
      await _realtime.subscribeNearbyLobbies(
        latitude: 10.7769,
        longitude: 106.7009,
        radiusKm: 50.0,
      );
    } catch (_) {
      // Realtime optional — tiếp tục dùng HTTP polling.
    }
  }

  Future<void> _joinAndOpen(String lobbyId) async {
    // Lỗi (vd: 409 đã là thành viên) → vẫn cho mở LobbyPage để check membership.
    await _lobbyCubit.joinLobby(lobbyId, null);
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LobbyPage(lobbyId: lobbyId, lobbyCubit: _lobbyCubit),
      ),
    );
  }

  Future<void> _openPreview(LobbyEntity lobby) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            LobbyPreviewPage(lobby: lobby, lobbyCubit: _lobbyCubit),
      ),
    );
  }

  void _randomJoin() {
    final state = _searchCubit.state;
    if (state is! LobbyListLoaded) return;
    final candidates = state.entities
        .where(
          (l) =>
              l.isPublic &&
              l.status == LobbyStatus.open &&
              l.currentPlayers < l.maxPlayers,
        )
        .toList();
    if (candidates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hiện không có phòng nào còn chỗ để ghép.'),
        ),
      );
      return;
    }
    candidates.shuffle();
    _joinAndOpen(candidates.first.id);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Auto-match'),
        centerTitle: false,
        actions: [
          IconButton(
            tooltip: 'Ghép ngẫu nhiên',
            icon: const Icon(Icons.shuffle),
            onPressed: _randomJoin,
          ),
        ],
      ),
      body: BlocBuilder<LobbySearchCubit, LobbyState>(
        bloc: _searchCubit,
        builder: (context, state) {
          if (state is LobbyListLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: AppSpacing.md),
                  Text('Đang tìm phòng phù hợp...'),
                ],
              ),
            );
          }

          if (state is LobbyFailure) {
            return _ErrorView(
              message: state.message,
              onRetry: () => _searchCubit.loadDiscoverable(limit: 50),
            );
          }

          final lobbies = state is LobbyListLoaded ? state.entities : <LobbyEntity>[];

          return RefreshIndicator(
            onRefresh: () async {
              await _searchCubit.loadDiscoverable(limit: 50);
            },
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.sm,
                      AppSpacing.md,
                      0,
                    ),
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.shuffle,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Để hệ thống ghép giúp bạn',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onPrimaryContainer,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Danh sách lobby công khai còn chỗ gần bạn. '
                                'Bấm vào phòng để xem chi tiết hoặc nhấn nút '
                                'shuffle để ghép ngẫu nhiên.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onPrimaryContainer,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (lobbies.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _EmptyAutoMatchView(
                      onRandom: _randomJoin,
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.md,
                      AppSpacing.md,
                      AppSpacing.lg,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _LobbyTile(
                          lobby: lobbies[index],
                          timeFormatter: _timeFormatter,
                          onTap: () => _openPreview(lobbies[index]),
                          onJoin: () => _joinAndOpen(lobbies[index].id),
                        ),
                        childCount: lobbies.length,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _LobbyTile extends StatelessWidget {
  final LobbyEntity lobby;
  final DateFormat timeFormatter;
  final VoidCallback onTap;
  final VoidCallback onJoin;

  const _LobbyTile({
    required this.lobby,
    required this.timeFormatter,
    required this.onTap,
    required this.onJoin,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final slotsRemaining = lobby.maxPlayers - lobby.currentPlayers;
    final hasSlots = slotsRemaining > 0 &&
        lobby.status == LobbyStatus.open;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lobby.gameName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      lobby.cafeName,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: 4,
                      children: [
                        _Chip(
                          icon: Icons.access_time,
                          label: timeFormatter.format(lobby.scheduledTime),
                        ),
                        _Chip(
                          icon: Icons.people,
                          label:
                              '${lobby.currentPlayers}/${lobby.maxPlayers}',
                        ),
                        if (lobby.distanceKm != null)
                          _Chip(
                            icon: Icons.location_on_outlined,
                            label:
                                '${lobby.distanceKm!.toStringAsFixed(1)} km',
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              FilledButton(
                onPressed: hasSlots ? onJoin : null,
                child: Text(hasSlots ? 'Ghép' : 'Đầy'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Chip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: theme.colorScheme.outline),
          const SizedBox(width: 4),
          Text(label, style: theme.textTheme.labelSmall),
        ],
      ),
    );
  }
}

class _EmptyAutoMatchView extends StatelessWidget {
  final VoidCallback onRandom;
  const _EmptyAutoMatchView({required this.onRandom});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.meeting_room_outlined,
            size: 80,
            color: colors.primary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Chưa có phòng nào để ghép',
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Bạn có thể thử lại sau, hoặc tạo phòng mới để mời bạn bè tham gia.',
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: colors.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: colors.error),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Không thể tải danh sách phòng',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.lg),
            OutlinedButton.icon(
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
