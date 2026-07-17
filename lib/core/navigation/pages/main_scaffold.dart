import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../di/injection.dart';
import '../../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../../features/auth/presentation/pages/login_page.dart';
import '../../../features/home/presentation/pages/home_overview_page.dart';
import '../../../features/lobby_management/presentation/cubit/lobby_cubit.dart';
import '../../../features/matchmaking_discovery/presentation/cubit/matchmaking_cubit.dart';
import '../../../features/profile/presentation/pages/home_page.dart';
import '../../../features/tournament/presentation/pages/tournament_page.dart';
import '../nav_tab.dart';
import '../navigation_cubit.dart';
import '../widgets/board_verse_nav_bar.dart';
import 'bookings_page.dart';
import 'discovery_tab.dart';

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  late final MatchmakingCubit _matchmakingCubit;
  late final LobbyCubit _lobbyCubit;
  late final PageController _pageController;
  int _previousIndex = 0;

  @override
  void initState() {
    super.initState();
    _matchmakingCubit = getIt<MatchmakingCubit>();
    _lobbyCubit = getIt<LobbyCubit>();
    _pageController = PageController(initialPage: 2); // Start at Discovery (index 2)
  }

  @override
  void dispose() {
    _pageController.dispose();
    _matchmakingCubit.close();
    _lobbyCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<NavigationCubit>(
          create: (_) => NavigationCubit(),
        ),
        BlocProvider<MatchmakingCubit>.value(value: _matchmakingCubit),
        BlocProvider<LobbyCubit>.value(value: _lobbyCubit),
      ],
      child: BlocConsumer<NavigationCubit, NavigationState>(
        listener: (context, state) {
          if (state.currentIndex != _previousIndex) {
            _pageController.animateToPage(
              state.currentIndex,
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOutCubic,
            );
            _previousIndex = state.currentIndex;
          }
        },
        builder: (context, state) {
          return PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, result) {
              if (!didPop) {
                _handleBackNavigation(context, state.currentIndex);
              }
            },
            child: Scaffold(
              body: PageView(
                controller: _pageController,
                physics: const BouncingScrollPhysics(),
                onPageChanged: (index) {
                  if (index != state.currentIndex) {
                    context.read<NavigationCubit>().setTab(index);
                  }
                },
                children: [
                  HomeOverviewPage(
                    matchmakingCubit: _matchmakingCubit,
                    onSwitchTab: (index) => context
                        .read<NavigationCubit>()
                        .setTab(index),
                  ),
                  const BookingsPage(), // Phòng chờ
                  DiscoveryTab(
                    matchmakingCubit: _matchmakingCubit,
                    lobbyCount: state.lobbyCount,
                  ),
                  const TournamentPage(),
                  const ProfileTab(),
                ],
              ),
              bottomNavigationBar: BoardVerseNavBar(
                currentIndex: state.currentIndex,
                lobbyCount: state.lobbyCount,
                hasBookingBadge: state.hasBookingBadge,
                isPlayingBadge: state.isPlayingBadge,
                friendInviteCount: state.friendInviteCount,
                onTabSelected: (index) {
                  _handleTabSelection(context, state.currentIndex, index);
                },
              ),
            ),
          );
        },
      ),
    );
  }

  void _handleTabSelection(BuildContext context, int currentIndex, int newIndex) {
    if (currentIndex == newIndex) {
      _handleDoubleTap(context, newIndex);
    } else {
      context.read<NavigationCubit>().setTab(newIndex);
    }
  }

  void _handleDoubleTap(BuildContext context, int tabIndex) {
    switch (tabIndex) {
      case 0:
        // Home refresh
        break;
      case 1:
        _matchmakingCubit.searchGames();
        break;
      case 2:
        // Refresh bookings
        break;
      case 3:
        // Tournament refresh - hiện đang là mock
        break;
    }
  }

  void _handleBackNavigation(BuildContext context, int currentIndex) {
    if (currentIndex != NavTab.home.tabIndex) {
      context.read<NavigationCubit>().goHome();
    } else {
      _showLogoutDialog(context);
    }
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc muốn đăng xuất không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<AuthCubit>().logout();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginPage()),
                (route) => false,
              );
            },
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
  }
}

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  @override
  Widget build(BuildContext context) {
    // HomePage calls getProfile() in its own initState — no duplicate call here.
    return const HomePage();
  }
}