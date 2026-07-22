import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../features/lobby_management/presentation/pages/nearby_lobbies_page.dart';
import '../../../features/matchmaking_discovery/presentation/cubit/matchmaking_cubit.dart';
import '../../../features/matchmaking_discovery/presentation/pages/search_page.dart';
import '../lobby_suggestion_signal.dart';

/// Tab Khám phá: bên trong có 2 tab con
/// - Tab "Khám phá game" → SearchPage (tìm game + cafe)
/// - Tab "Phòng chờ" → NearbyLobbiesPage (xem/search/join/create lobby)
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
    // Listen yêu cầu "chuyển sang Lobby screen cho game X" — khi có,
    // snap inner TabBar sang "Phòng chờ" (index 1). NearbyLobbiesPage
    // sẽ consume signal để preselect game.
    LobbySuggestionSignal.instance.addListener(_switchToLobbyTab);
  }

  void _reset() {
    if (!mounted) return;
    _tabController.animateTo(0);
  }

  void _switchToLobbyTab() {
    if (!mounted) return;
    _tabController.animateTo(1);
  }

  @override
  void dispose() {
    DiscoveryResetSignal.instance.removeListener(_reset);
    LobbySuggestionSignal.instance.removeListener(_switchToLobbyTab);
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
          // FAB chỉ hiển thị khi đang ở sub-tab "Phòng chờ" — đây là CTA
          // chính cho flow tạo lobby (xem `_onCreateLobbyPressed` trong
          // `NearbyLobbiesPage`). Không còn mở SearchPage từ đây nữa vì
          // theo phân chia nghiệp vụ mới, Discovery chỉ tập trung vào
          // tìm boardgame + cafe gần — mọi flow lobby phải đi qua screen
          // lobby (`NearbyLobbiesPage`).
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
    // Đẩy user xuống `NearbyLobbiesPage` (sub-tab "Phòng chờ") thông qua
    // cách scroll lên top và trigger create. Vì NearbyLobbiesPage đã có
    // logic tạo lobby riêng, ta chỉ cần thông báo để nó hiển thị game
    // picker. Tuy nhiên flow đơn giản nhất: snap vào "Phòng chờ" và để
    // FAB `NearbyLobbiesPage` xử lý (khi FAB của tab này chỉ là visual,
    // hành động thực tế đã được NearbyLobbiesPage gắn vào header action).
    // Tại đây ta chỉ cần đảm bảo FAB đã chuyển tab — phần xử lý game
    // picker đã được gắn vào IconButton `AppIcons.add` ở AppBar của
    // NearbyLobbiesPage.
    if (_tabController.index != 1) {
      _tabController.animateTo(1);
    }
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