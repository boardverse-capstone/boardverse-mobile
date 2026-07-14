import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../di/injection.dart';
import '../../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../../features/auth/presentation/pages/login_page.dart';
import '../../../features/home/presentation/pages/home_overview_page.dart';
import '../../../features/lobby_management/presentation/cubit/lobby_cubit.dart';
import '../../../features/matchmaking_discovery/presentation/cubit/matchmaking_cubit.dart';
import '../../../features/profile/presentation/cubit/profile_cubit.dart';
import '../../../features/profile/presentation/pages/home_page.dart';
import '../../../features/tournament/presentation/pages/tournament_page.dart';
import '../nav_tab.dart';
import '../navigation_cubit.dart';
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
                  DiscoveryTab(
                    matchmakingCubit: _matchmakingCubit,
                    lobbyCount: state.lobbyCount,
                  ),
                  const BookingsPage(),
                  HomeOverviewPage(
                    matchmakingCubit: _matchmakingCubit,
                    onSwitchTab: (index) => context
                        .read<NavigationCubit>()
                        .setTab(index),
                  ),
                  const TournamentPage(),
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
    final theme = Theme.of(context);

    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        NavigationBar(
          selectedIndex: currentIndex,
          onDestinationSelected: onTabSelected,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          animationDuration: const Duration(milliseconds: 300),
          height: 76,
          destinations: [
            NavigationDestination(
              icon: Badge(
                isLabelVisible: lobbyCount > 0,
                label: Text('$lobbyCount'),
                child: const Icon(Icons.explore_outlined),
              ),
              selectedIcon: Badge(
                isLabelVisible: lobbyCount > 0,
                label: Text('$lobbyCount'),
                child: const Icon(Icons.explore),
              ),
              label: 'Khám phá',
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
              icon: SizedBox.shrink(),
              selectedIcon: SizedBox.shrink(),
              label: '',
            ),
            const NavigationDestination(
              icon: Icon(Icons.emoji_events_outlined),
              selectedIcon: Icon(Icons.emoji_events),
              label: 'Giải đấu',
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
        ),
        _CenterHomeButton(
          isSelected: currentIndex == NavTab.home.tabIndex,
          onTap: () => onTabSelected(NavTab.home.tabIndex),
          theme: theme,
        ),
      ],
    );
  }
}

class _CenterHomeButton extends StatelessWidget {
  final bool isSelected;
  final VoidCallback onTap;
  final ThemeData theme;

  const _CenterHomeButton({
    required this.isSelected,
    required this.onTap,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final bottomInset = mediaQuery.padding.bottom;
    return Positioned(
      bottom: 22 + bottomInset,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isSelected
                      ? [
                          theme.colorScheme.primary,
                          theme.colorScheme.tertiary,
                        ]
                      : [
                          theme.colorScheme.primary,
                          theme.colorScheme.secondary,
                        ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(
                  color: theme.colorScheme.surface,
                  width: 4,
                ),
              ),
              child: Icon(
                isSelected ? Icons.home_rounded : Icons.home_outlined,
                color: Colors.white,
                size: 30,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Trang chủ',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}