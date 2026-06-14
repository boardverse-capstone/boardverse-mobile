import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../di/injection.dart';
import '../../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../../features/auth/presentation/pages/login_page.dart';
import '../../../features/lobby_management/presentation/cubit/lobby_cubit.dart';
import '../../../features/matchmaking_discovery/presentation/cubit/matchmaking_cubit.dart';
import '../../../features/matchmaking_discovery/presentation/pages/search_page.dart';
import '../../../features/profile/presentation/cubit/profile_cubit.dart';
import '../../../features/profile/presentation/pages/home_page.dart';
import '../navigation_cubit.dart';
import 'bookings_page.dart';
import 'leaderboard_page.dart';
import 'lobbies_page.dart';

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  late final MatchmakingCubit _matchmakingCubit;
  late final LobbyCubit _lobbyCubit;

  @override
  void initState() {
    super.initState();
    _matchmakingCubit = getIt<MatchmakingCubit>();
    _lobbyCubit = getIt<LobbyCubit>();
  }

  @override
  void dispose() {
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
      child: BlocBuilder<NavigationCubit, NavigationState>(
        builder: (context, state) {
          return PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, result) {
              if (!didPop) {
                _handleBackNavigation(context, state.currentIndex);
              }
            },
            child: Scaffold(
              body: IndexedStack(
                index: state.currentIndex,
                children: [
                  DiscoveryTab(cubits: CubitsHolder(
                    matchmakingCubit: _matchmakingCubit,
                  )),
                  const LobbiesPage(),
                  const BookingsPage(),
                  const LeaderboardPage(),
                  const ProfileTab(),
                ],
              ),
              bottomNavigationBar: _BottomNavBar(
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
        _matchmakingCubit.searchGames();
        break;
      case 1:
        // Refresh lobbies
        break;
      case 2:
        // Refresh bookings
        break;
    }
  }

  void _handleBackNavigation(BuildContext context, int currentIndex) {
    switch (currentIndex) {
      case 0:
      case 1:
      case 2:
      case 3:
        context.read<NavigationCubit>().setTab(4);
        break;
      case 4:
        _showLogoutDialog(context);
        break;
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

class CubitsHolder {
  final MatchmakingCubit matchmakingCubit;

  CubitsHolder({required this.matchmakingCubit});
}

class DiscoveryTab extends StatelessWidget {
  final CubitsHolder cubits;

  const DiscoveryTab({super.key, required this.cubits});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: cubits.matchmakingCubit,
      child: SearchPage(matchmakingCubit: cubits.matchmakingCubit),
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
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) {
        context.read<ProfileCubit>().getProfile();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const HomePage();
  }
}

class _BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final int lobbyCount;
  final bool hasBookingBadge;
  final bool isPlayingBadge;
  final int friendInviteCount;
  final Function(int) onTabSelected;

  const _BottomNavBar({
    required this.currentIndex,
    required this.lobbyCount,
    required this.hasBookingBadge,
    required this.isPlayingBadge,
    required this.friendInviteCount,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: onTabSelected,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      animationDuration: const Duration(milliseconds: 300),
      destinations: [
        const NavigationDestination(
          icon: Icon(Icons.explore_outlined),
          selectedIcon: Icon(Icons.explore),
          label: 'Khám phá',
        ),
        NavigationDestination(
          icon: Badge(
            isLabelVisible: lobbyCount > 0,
            label: Text('$lobbyCount'),
            child: const Icon(Icons.groups_outlined),
          ),
          selectedIcon: Badge(
            isLabelVisible: lobbyCount > 0,
            label: Text('$lobbyCount'),
            child: const Icon(Icons.groups),
          ),
          label: 'Phòng chờ',
        ),
        NavigationDestination(
          icon: Badge(
            isLabelVisible: hasBookingBadge,
            backgroundColor: Colors.red,
            child: const Icon(Icons.calendar_today_outlined),
          ),
          selectedIcon: Badge(
            isLabelVisible: hasBookingBadge,
            backgroundColor: Colors.red,
            child: const Icon(Icons.calendar_today),
          ),
          label: 'Lịch hẹn',
        ),
        const NavigationDestination(
          icon: Icon(Icons.leaderboard_outlined),
          selectedIcon: Icon(Icons.leaderboard),
          label: 'Xếp hạng',
        ),
        NavigationDestination(
          icon: Badge(
            isLabelVisible: friendInviteCount > 0,
            label: Text('$friendInviteCount'),
            child: const Icon(Icons.person_outline),
          ),
          selectedIcon: Badge(
            isLabelVisible: friendInviteCount > 0,
            label: Text('$friendInviteCount'),
            child: const Icon(Icons.person),
          ),
          label: 'Cá nhân',
        ),
      ],
    );
  }
}
