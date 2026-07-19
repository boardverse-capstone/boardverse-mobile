import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../features/lobby_management/presentation/pages/nearby_lobbies_page.dart';
import '../../../features/matchmaking_discovery/presentation/cubit/matchmaking_cubit.dart';
import '../../../features/matchmaking_discovery/presentation/pages/lobby_config_page.dart';
import '../../../features/matchmaking_discovery/presentation/pages/search_page.dart';

/// Tab Khám phá: bên trong có 2 tab con
/// - Tab "Khám phá game" → SearchPage (tìm game + cafe)
/// - Tab "Phòng chờ" → NearbyLobbiesPage (tìm phòng gần đây)
class DiscoveryTab extends StatefulWidget {
  const DiscoveryTab({super.key});

  /// Asks the active [DiscoveryTab] (if any) to snap its inner TabBar back
  /// to the "Khám phá game" sub-tab. Safe to call when not mounted.
  static void requestReset(BuildContext context) {
    DiscoveryResetSignal.instance.notify();
  }

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
    DiscoveryResetSignal.instance.addListener(_reset);
  }

  void _reset() {
    if (!mounted) return;
    _tabController.animateTo(0);
  }

  @override
  void dispose() {
    DiscoveryResetSignal.instance.removeListener(_reset);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
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
          const _DiscoveryGameTab(),
          const NearbyLobbiesPage(),
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
          matchmakingCubit: context.read<MatchmakingCubit>(),
        ),
      ),
    );
  }
}

/// Wraps SearchPage so the discovery tab can resolve the matchmaking cubit
/// from its own BlocProvider scope (it is provided by the parent MultiBloc
/// in main.dart).
class _DiscoveryGameTab extends StatelessWidget {
  const _DiscoveryGameTab();

  @override
  Widget build(BuildContext context) {
    return SearchPage(
      matchmakingCubit: context.read<MatchmakingCubit>(),
    );
  }
}

/// Broadcast notifier used to ask the active DiscoveryTab to reset its
/// inner sub-tab from the bottom-nav double-tap handler.
class DiscoveryResetSignal extends ChangeNotifier {
  DiscoveryResetSignal._();
  static final DiscoveryResetSignal instance = DiscoveryResetSignal._();

  void notify() {
    if (hasListeners) notifyListeners();
  }
}