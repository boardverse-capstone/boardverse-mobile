import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../features/lobby_management/presentation/pages/nearby_lobbies_page.dart';
import '../../../features/matchmaking_discovery/presentation/cubit/matchmaking_cubit.dart';
import '../../../features/matchmaking_discovery/presentation/pages/search_page.dart';
import '../../../features/matchmaking_discovery/presentation/pages/lobby_config_page.dart';

/// Tab Khám phá: bên trong có 2 tab con
/// - Tab "Khám phá" → SearchPage (tìm game + cafe)
/// - Tab "Phòng chờ" → NearbyLobbiesPage (tìm phòng gần đây)
class DiscoveryTab extends StatefulWidget {
  final MatchmakingCubit matchmakingCubit;
  final int lobbyCount;

  const DiscoveryTab({
    super.key,
    required this.matchmakingCubit,
    required this.lobbyCount,
  });

  @override
  State<DiscoveryTab> createState() => _DiscoveryTabState();
}

class _DiscoveryTabState extends State<DiscoveryTab>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Khám phá'),
        centerTitle: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: theme.colorScheme.surface,
            child: TabBar(
              controller: _tabController,
              isScrollable: false,
              labelColor: theme.colorScheme.primary,
              unselectedLabelColor: theme.colorScheme.outline,
              indicatorColor: theme.colorScheme.primary,
              indicatorSize: TabBarIndicatorSize.label,
              indicatorWeight: 3,
              labelStyle: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              tabs: const [
                Tab(icon: Icon(Icons.extension), text: 'Khám phá game'),
                Tab(
                  icon: Icon(Icons.groups_outlined),
                  text: 'Phòng chờ',
                ),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          DiscoveryGameTab(matchmakingCubit: widget.matchmakingCubit),
          NearbyLobbiesPage(),
        ],
      ),
      floatingActionButton: AnimatedBuilder(
        animation: _tabController,
        builder: (context, _) {
          if (_tabController.index != 1) return const SizedBox.shrink();
          return FloatingActionButton.extended(
            heroTag: 'discovery_lobby_fab',
            onPressed: () => _openCreateLobby(context),
            icon: const Icon(Icons.add),
            label: const Text('Tạo phòng'),
          );
        },
      ),
    );
  }

  void _openCreateLobby(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LobbyConfigPage(
          gameId: 'demo',
          gameName: 'Demo Game',
          cafeId: 'demo_cafe',
          cafeName: 'Demo Cafe',
          matchmakingCubit: widget.matchmakingCubit,
        ),
      ),
    );
  }
}

/// Wrapper riêng để expose SearchPage qua TabBar (giữ logic nguyên bản).
class DiscoveryGameTab extends StatelessWidget {
  final MatchmakingCubit matchmakingCubit;

  const DiscoveryGameTab({super.key, required this.matchmakingCubit});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<MatchmakingCubit>.value(
      value: matchmakingCubit,
      child: SearchPage(matchmakingCubit: matchmakingCubit),
    );
  }
}
