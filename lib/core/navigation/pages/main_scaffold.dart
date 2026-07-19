import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../features/home/presentation/pages/home_overview_page.dart';
import '../../../features/matchmaking_discovery/presentation/cubit/matchmaking_cubit.dart';
import '../nav_tab.dart';
import '../navigation_cubit.dart';
import '../widgets/board_verse_nav_bar.dart';
import 'bookings_page.dart';
import 'discovery_tab.dart';
import 'profile_page.dart';
import 'tournament_page.dart';

/// Single source of truth for tab switching is [PageController] — the Cubit
/// is treated as a read-only mirror that the nav bar / back handler can
/// observe but never drive animation directly. This eliminates the
/// "PageController says X, Cubit says Y" race that previously caused
/// mismatched highlight / body combinations.
class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  static const _animationDuration = Duration(milliseconds: 350);
  static const _initialIndex = 0; // Home

  late final PageController _pageController;
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _initialIndex);
    // Sync the Cubit with the initial page so the nav bar reflects the
    // starting tab on first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<NavigationCubit>().setTab(_initialIndex);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Drives [PageController] from a nav-bar tap. Holds the only animation
  /// trigger — the Cubit is updated as a side effect via [onPageChanged].
  void _onTabTapped(int index) {
    final clamped = index.clamp(0, NavTab.values.length - 1).toInt();
    final current = _pageController.hasClients
        ? _pageController.page?.round() ?? _initialIndex
        : _initialIndex;
    if (clamped == current) {
      _handleDoubleTap(clamped);
      return;
    }
    if (_isAnimating) return;
    _isAnimating = true;
    _pageController
        .animateToPage(
      clamped,
      duration: _animationDuration,
      curve: Curves.easeOutCubic,
    )
        .whenComplete(() {
      if (mounted) _isAnimating = false;
    });
  }

  /// Double-tap logic per tab:
  /// - Home (0): no-op (scroll-to-top owned by HomeOverviewPage)
  /// - Bookings (1): reload upcoming + history
  /// - Discovery (2): reset inner sub-tab to "Khám phá game"
  /// - Tournament (3): no-op (mock data, no refresh needed yet)
  /// - Profile (4): no-op (data is already cached)
  void _handleDoubleTap(int tabIndex) {
    switch (tabIndex) {
      case 1:
        BookingsPage.requestRefresh(context);
        break;
      case 2:
        DiscoveryTab.requestReset(context);
        break;
      case 3:
        TournamentPage.requestRefresh(context);
        break;
      case 0:
      case 4:
        break;
    }
  }

  /// Mirrors the [PageController] page into the [NavigationCubit] so the
  /// nav bar can rebuild via [BlocSelector]. This is the ONLY place we
  /// mutate the Cubit from the page-switching path — taps never write to
  /// the Cubit directly.
  void _onPageChanged(int index) {
    final clamped = index.clamp(0, NavTab.values.length - 1).toInt();
    context.read<NavigationCubit>().setTab(clamped);
  }

  /// Allows descendants (e.g. HomeOverviewPage quick actions) to request
  /// a tab switch. Animates the PageController and lets [onPageChanged]
  /// update the Cubit as a side effect.
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
    return BlocProvider<NavigationCubit>(
      create: (_) => NavigationCubit(),
      child: BlocBuilder<NavigationCubit, NavigationState>(
        buildWhen: (prev, curr) => prev.currentIndex != curr.currentIndex,
        builder: (context, state) {
          return PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, _) {
              if (didPop) return;
              _handleBackNavigation(state.currentIndex);
            },
            child: Scaffold(
              body: PageView.builder(
                controller: _pageController,
                physics: const BouncingScrollPhysics(),
                onPageChanged: _onPageChanged,
                itemCount: NavTab.values.length,
                itemBuilder: (context, index) => _TabPage(
                  index: index,
                  onSwitchTab: _requestTab,
                ),
              ),
              bottomNavigationBar: BoardVerseNavBar(
                onTabSelected: _onTabTapped,
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Resolves the page widget for a given tab index.
///
/// The widget tree is intentionally built once per tab and held in memory
/// for the lifetime of the PageView.builder, so subsequent tab switches
/// don't re-create stateful pages.
class _TabPage extends StatelessWidget {
  final int index;
  final ValueChanged<int> onSwitchTab;

  const _TabPage({
    required this.index,
    required this.onSwitchTab,
  });

  @override
  Widget build(BuildContext context) {
    switch (index) {
      case 0:
        return HomeOverviewPage(
          matchmakingCubit: context.read<MatchmakingCubit>(),
          onSwitchTab: onSwitchTab,
        );
      case 1:
        return const BookingsPage();
      case 2:
        return const DiscoveryTab();
      case 3:
        return const TournamentPage();
      case 4:
        return const ProfilePage();
      default:
        return const SizedBox.shrink();
    }
  }
}