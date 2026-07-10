import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/error/failures.dart';
import '../../../matchmaking_discovery/presentation/pages/lobby_config_page.dart';
import '../../domain/entities/lobby_summary.dart';
import '../cubit/lobby_cubit.dart';
import '../cubit/lobby_search_cubit.dart';
import '../cubit/lobby_state.dart';
import 'lobby_page.dart';

/// Trang danh sách lobby khả dụng quanh user (BR-10 + BR-08).
///
/// - Filter theo bán kính & Karma (slider trên top).
/// - Pull-to-refresh.
/// - Tap card → join lobby → navigate LobbyPage.
class NearbyLobbiesPage extends StatefulWidget {
  const NearbyLobbiesPage({super.key});

  @override
  State<NearbyLobbiesPage> createState() => _NearbyLobbiesPageState();
}

class _NearbyLobbiesPageState extends State<NearbyLobbiesPage> {
  double _radiusKm = 10.0;
  double _minKarma = 0.0;

  late final LobbySearchCubit _searchCubit;
  late final LobbyCubit _lobbyCubit;

  @override
  void initState() {
    super.initState();
    _searchCubit = getIt<LobbySearchCubit>();
    _lobbyCubit = getIt<LobbyCubit>();
    _runSearch();
  }

  @override
  void dispose() {
    _searchCubit.close();
    super.dispose();
  }

  void _runSearch() {
    _searchCubit.searchNearbyLobbies(
      filter: LobbySearchFilter(
        radiusKm: _radiusKm,
        minKarma: _minKarma,
        excludeOwnLobbies: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tìm phòng chờ'),
        actions: [
          IconButton(
            tooltip: 'Tạo phòng mới',
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => LobbyConfigPage(
                    gameId: 'demo',
                    gameName: 'Demo Game',
                    cafeId: 'demo_cafe',
                    cafeName: 'Demo Cafe',
                    matchmakingCubit: getIt(),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _FilterBar(
            radiusKm: _radiusKm,
            minKarma: _minKarma,
            onRadiusChanged: (v) {
              setState(() => _radiusKm = v);
              _runSearch();
            },
            onKarmaChanged: (v) {
              setState(() => _minKarma = v);
              _runSearch();
            },
          ),
          const Divider(height: 1),
          Expanded(
            child: BlocBuilder<LobbySearchCubit, LobbyState>(
              bloc: _searchCubit,
              builder: (context, state) {
                if (state is LobbyListLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is LobbyListEmpty) {
                  return _EmptyView(message: state.message);
                }
                if (state is LobbyFailure) {
                  return _EmptyView(
                    message: state.message,
                    isError: true,
                    onRetry: _runSearch,
                  );
                }
                if (state is LobbyListLoaded) {
                  return RefreshIndicator(
                    onRefresh: () async => _runSearch(),
                    child: ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: state.lobbies.length,
                      itemBuilder: (context, index) {
                        return _LobbyCard(
                          lobby: state.lobbies[index],
                          onJoin: (lobby) => _joinAndOpen(lobby),
                          theme: theme,
                        );
                      },
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _joinAndOpen(LobbySummary lobby) async {
    final joinResult = await _lobbyCubit.joinLobby(lobby.id, null);
    if (!mounted) return;
    final failureOrLobby = joinResult.fold<Failure?>(
      (f) => f,
      (_) => null,
    );
    if (failureOrLobby != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(failureOrLobby.message)),
      );
      return;
    }
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LobbyPage(
          lobbyId: lobby.id,
          lobbyCubit: _lobbyCubit,
        ),
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  final double radiusKm;
  final double minKarma;
  final ValueChanged<double> onRadiusChanged;
  final ValueChanged<double> onKarmaChanged;

  const _FilterBar({
    required this.radiusKm,
    required this.minKarma,
    required this.onRadiusChanged,
    required this.onKarmaChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      color: theme.colorScheme.surfaceContainerHighest,
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.location_on, size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text('Bán kính:', style: theme.textTheme.bodyMedium),
              const Spacer(),
              Text(
                '${radiusKm.toStringAsFixed(1)} km',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Slider(
            value: radiusKm,
            min: 1,
            max: 30,
            divisions: 29,
            label: '${radiusKm.toStringAsFixed(1)} km',
            onChanged: onRadiusChanged,
          ),
          Row(
            children: [
              Icon(Icons.star, size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text('Karma ≥:', style: theme.textTheme.bodyMedium),
              const Spacer(),
              Text(
                '${minKarma.toInt()}',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Slider(
            value: minKarma,
            min: 0,
            max: 100,
            divisions: 20,
            label: '${minKarma.toInt()} Karma',
            onChanged: onKarmaChanged,
          ),
        ],
      ),
    );
  }
}

class _LobbyCard extends StatelessWidget {
  final LobbySummary lobby;
  final void Function(LobbySummary) onJoin;
  final ThemeData theme;

  const _LobbyCard({
    required this.lobby,
    required this.onJoin,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('HH:mm');
    final distance = lobby.distanceKm < 1
        ? '${(lobby.distanceKm * 1000).toInt()} m'
        : '${lobby.distanceKm.toStringAsFixed(1)} km';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => onJoin(lobby),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: lobby.gameImageUrl.isNotEmpty
                    ? Image.network(
                        lobby.gameImageUrl,
                        width: 72,
                        height: 72,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            _placeholderIcon(theme),
                      )
                    : _placeholderIcon(theme),
              ),
              const SizedBox(width: 12),
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
                      style: theme.textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.location_on,
                            size: 14, color: theme.colorScheme.outline),
                        const SizedBox(width: 4),
                        Text(distance, style: theme.textTheme.bodySmall),
                        const SizedBox(width: 12),
                        Icon(Icons.star,
                            size: 14, color: Colors.amber.shade700),
                        const SizedBox(width: 4),
                        Text(
                          '≥ ${lobby.minimumKarma.toInt()}',
                          style: theme.textTheme.bodySmall,
                        ),
                        const SizedBox(width: 12),
                        Icon(Icons.access_time,
                            size: 14, color: theme.colorScheme.outline),
                        const SizedBox(width: 4),
                        Text(
                          dateFmt.format(lobby.scheduledTime),
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${lobby.currentPlayers}/${lobby.maxPlayers}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'còn ${lobby.slotsRemaining} chỗ',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholderIcon(ThemeData theme) => Container(
        width: 72,
        height: 72,
        color: theme.colorScheme.surfaceContainerHighest,
        child: Icon(
          Icons.extension,
          color: theme.colorScheme.outline,
        ),
      );
}

class _EmptyView extends StatelessWidget {
  final String message;
  final bool isError;
  final VoidCallback? onRetry;

  const _EmptyView({
    required this.message,
    this.isError = false,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.search_off,
              size: 56,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Thử lại'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
