import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../features/home/presentation/pages/home_overview_page.dart';
import '../../../features/matchmaking_discovery/presentation/cubit/matchmaking_cubit.dart';
import '../lobby_join_signal.dart';
import '../lobby_suggestion_signal.dart';
import '../nav_tab.dart';
import '../navigation_cubit.dart';
import '../widgets/board_verse_nav_bar_neo.dart';
import '../widgets/lazy_indexed_stack.dart';
import 'bookings_page.dart';
import 'discovery_tab.dart';
import 'profile_page.dart';
import 'tournament_page.dart';

/// Main scaffold with bottom navigation bar.
///
/// Uses IndexedStack for instant tab switching without animation effects.
class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key, this.initialTabIndex});

  /// Index tab để mở ban đầu (dùng cho deep-link SePay return).
  final int? initialTabIndex;

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  static const _defaultInitialIndex = 0; // Home
  late final NavigationCubit _navigationCubit;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTabIndex ?? _defaultInitialIndex;
    _navigationCubit = NavigationCubit();
    // Listen yêu cầu "chuyển sang Lobby screen cho game X" từ
    // BoardGameDetailPage (khi user bấm "Chơi cùng nhóm").
    LobbySuggestionSignal.instance.addListener(_handleLobbySuggestion);
    // Listen yêu cầu "navigate đến LobbyPage" sau khi accept invite.
    LobbyJoinSignal.instance.addListener(_handleLobbyJoin);
  }

  void _handleLobbySuggestion() {
    // Chuyển sang tab Discovery (index 2). DiscoveryTab sẽ tự switch
    // sub-tab sang "Phòng chờ" và NearbyLobbiesPage sẽ consume signal để
    // preselect game.
    _onTabTapped(NavTab.discovery.tabIndex);
  }

  /// Navigate to LobbyPage after invite accept.
  void _handleLobbyJoin() {
    final lobbyId = LobbyJoinSignal.instance.pendingLobbyId;
    if (lobbyId == null) return;

    LobbyJoinSignal.instance.consume();

    // Pop current route (invites page) then push lobby page.
    Navigator.of(context)
        .popUntil((route) => route.isFirst);
    Navigator.of(context).pushNamed(
      '/lobby/page',
      arguments: {'lobbyId': lobbyId},
    );
  }

  @override
  void dispose() {
    LobbySuggestionSignal.instance.removeListener(_handleLobbySuggestion);
    LobbyJoinSignal.instance.removeListener(_handleLobbyJoin);
    _navigationCubit.close();
    super.dispose();
  }

  /// Drives tab switching without animation. Uses [LazyIndexedStack] so
  /// that tabs which the user has never opened do not run their `initState`
  /// (and therefore do not trigger their initial GET requests) until they
  /// are actually selected.
  void _onTabTapped(int index) {
    final clamped = index.clamp(0, NavTab.values.length - 1).toInt();
    if (clamped == _currentIndex) {
      _handleDoubleTap(clamped);
      return;
    }
    setState(() {
      _currentIndex = clamped;
    });
    _navigationCubit.setTab(clamped);
  }

  /// Double-tap logic per tab:
  /// - Home (0): no-op (scroll-to-top owned by HomeOverviewPage)
  /// - Bookings (1): no-op (data auto-loads on first build)
  /// - Discovery (2): reset inner sub-tab to "Khám phá game"
  /// - Tournament (3): no-op (mock data, no refresh needed yet)
  /// - Profile (4): no-op (data is already cached)
  void _handleDoubleTap(int tabIndex) {
    switch (tabIndex) {
      case 2:
        DiscoveryTab.requestReset(context);
        break;
      case 3:
        TournamentPage.requestRefresh(context);
        break;
      case 0:
      case 1:
      case 4:
        break;
    }
  }

  /// Allows descendants (e.g. HomeOverviewPage quick actions) to request
  /// a tab switch.
  void _requestTab(int index) {
    _onTabTapped(index);
  }

  void _handleBackNavigation(int currentIndex) {
    if (currentIndex != NavTab.home.tabIndex) {
      _requestTab(NavTab.home.tabIndex);
      return;
    }
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Thoát ứng dụng'),
        content: const Text('Bạn có chắc muốn thoát BoardVerse?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Huỷ'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              SystemNavigator.pop();
            },
            child: const Text('Thoát'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<NavigationCubit>.value(
      value: _navigationCubit,
      child: BlocBuilder<NavigationCubit, NavigationState>(
        buildWhen: (prev, curr) => prev.currentIndex != curr.currentIndex,
        builder: (context, state) {
          return PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, _) {
              if (didPop) return;
              _handleBackNavigation(_currentIndex);
            },
            child: Scaffold(
              body: LazyIndexedStack(
                index: _currentIndex,
                children: [
                  HomeOverviewPage(
                    matchmakingCubit: context.read<MatchmakingCubit>(),
                    onSwitchTab: _requestTab,
                  ),
                  const BookingsPage(),
                  const DiscoveryTab(),
                  const TournamentPage(),
                  const ProfilePage(),
                ],
              ),
              bottomNavigationBar: BoardVerseNavBarNeo(
                onTabSelected: _onTabTapped,
              ),
            ),
          );
        },
      ),
    );
  }
}
