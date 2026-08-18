import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../features/profile/presentation/cubit/profile_cubit.dart';
import '../../../features/profile/presentation/pages/setup_profile_gate.dart';
import '../../../features/lobby_management/lobby_routes.dart';
import '../lobby_join_signal.dart';
import '../lobby_suggestion_signal.dart';
import '../nav_tab.dart';
import '../navigation_cubit.dart';
import '../widgets/board_verse_nav_bar_neo.dart';
import '../widgets/lazy_indexed_stack.dart';
import 'activity_page.dart';
import 'bookings_page.dart';
import 'explore_tab.dart';
import 'lobbies_page.dart';
import 'profile_page.dart';

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
  static const _defaultInitialIndex = 0; // Activity
  late final NavigationCubit _navigationCubit;
  late int _currentIndex;

  /// Counter bumped every time the user taps the Activity tab.
  ///
  /// Used as part of the [ActivityPage] widget's [ValueKey] so that
  /// tapping the tab forces Flutter to dispose the cached widget
  /// and rebuild a fresh one — which in turn re-runs `initState`
  /// and re-fetches the profile + tournaments.
  ///
  /// Other tabs keep a stable key so the [LazyIndexedStack] can
  /// continue to cache their state.
  int _activityKey = 0;

  /// Counter that fires the [ActivityPage.onReselect] callback without
  /// rebuilding the page from scratch. Bumped every time the user taps
  /// the Activity tab (including double-tap while already on it) so the
  /// greeting card always re-fetches `/api/UserProfile`.
  int _activityReselectTick = 0;

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

    // Đảm bảo [ProfileCubit] đã load profile trước khi [SetupProfileGate]
    // đánh giá `hasProfile`. Tránh trường hợp MainScaffold mount nhưng
    // cubit vẫn ở `ProfileInitial` → gate không biết phải chặn hay không.
    // `hydrateFromCache` đồng bộ UI với cache ngay lập tức, rồi
    // `getProfile` đi network để có data mới nhất.
    Future.microtask(() {
      if (!mounted) return;
      final cubit = context.read<ProfileCubit>();
      cubit.hydrateFromCache();
      cubit.getProfile();
    });
  }

  void _handleLobbySuggestion() {
    // Chuyển sang tab Lobbies (index 3)
    _onTabTapped(NavTab.lobbies.tabIndex);
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
      LobbyRoutes.lobbyPage,
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
      // Bump the Activity key so the next time Activity becomes
      // visible, `ActivityPage` is rebuilt from scratch and its
      // `initState` re-fetches the profile + tournaments.
      if (clamped == NavTab.activity.tabIndex) {
        _activityKey++;
      }
    });
    _navigationCubit.setTab(clamped);
  }

  /// Double-tap logic per tab:
  /// - Activity (0): re-fire onReselect so the page re-fetches the
  ///   profile + tournaments even when the tab is already active.
  ///   Without this, a previous failed fetch could leave the greeting
  ///   card skeletonised forever.
  /// - Other tabs: no-op (each page handles its own refresh).
  void _handleDoubleTap(int tabIndex) {
    if (tabIndex == NavTab.activity.tabIndex) {
      setState(() {
        _activityReselectTick++;
      });
    }
  }

  /// Allows descendants (e.g. ActivityPage quick actions) to request
  /// a tab switch.
  void _requestTab(int index) {
    _onTabTapped(index);
  }

  void _handleBackNavigation(int currentIndex) {
    if (currentIndex != NavTab.activity.tabIndex) {
      _requestTab(NavTab.activity.tabIndex);
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
            // [SetupProfileGate] lắng nghe [ProfileCubit] và push
            // SetupProfilePage full-screen khi `hasProfile = false`.
            // Cơ chế push route (thay vì in-place swap) đảm bảo
            // BottomNav bị che tự động, không cần truyền qua
            // wrapper.
            body: SetupProfileGate(
              child: LazyIndexedStack(
                index: _currentIndex,
                children: [
                  // Each child is wrapped in a ValueKey keyed by the
                  // currently-active tab so that switching back to the
                  // Activity tab causes a new `ActivityPage` instance
                  // to be built (and therefore its `initState` runs
                  // again, refetching the profile + tournaments).
                  //
                  // For all *other* tabs we keep a stable key so the
                  // LazyIndexedStack can still cache their state and
                  // skip their initial fetch on first switch.
                  if (_currentIndex == NavTab.activity.tabIndex)
                    ActivityPage(
                      key: ValueKey(_activityKey),
                      onSwitchTab: _requestTab,
                      // Bumping [_activityReselectTick] forces Flutter to
                      // rebuild the same widget instance, which fires
                      // [ActivityPage.didUpdateWidget] and triggers a
                      // refresh without disposing any state.
                      onReselect: () => _activityReselectTick,
                    )
                  else
                    const ActivityPage(key: ValueKey('activity-cached')),
                  const BookingsPage(),
                  const ExploreTab(),
                  const LobbiesPage(),
                  const ProfilePage(),
                ],
              ),
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
