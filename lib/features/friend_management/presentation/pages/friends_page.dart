import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_spacing.dart';
import '../cubit/cubit.dart';
import 'tabs/friend_requests_tab.dart';
import 'tabs/friends_list_tab.dart';
import 'tabs/search_users_tab.dart';

/// Main Friends page with 3 tabs:
/// - Bạn bè (Friends) — [FriendsListTab]
/// - Lời mời (Friend Requests) — [FriendRequestsTab]
/// - Tìm kiếm (Search Users) — [SearchUsersTab]
///
/// Loading strategy (per-tab, lazy):
/// - NOT call any API on mount — wait for user to switch to a tab
/// - Tab "Bạn bè" → `loadFriends()`
/// - Tab "Lời mời" → `loadReceivedRequests()`
/// - Tab "Tìm kiếm" → on-demand via debounce, call `searchUsers(query)`
class FriendsPage extends StatelessWidget {
  const FriendsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<FriendListCubit>(),
      child: const _FriendsScaffold(),
    );
  }
}

class _FriendsScaffold extends StatefulWidget {
  const _FriendsScaffold();

  @override
  State<_FriendsScaffold> createState() => _FriendsScaffoldState();
}

class _FriendsScaffoldState extends State<_FriendsScaffold>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  /// Track which tabs have been loaded — avoid calling API multiple times
  /// when user switches back and forth.
  final Set<int> _loadedTabs = <int>{};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      _loadIfNeeded(_tabController.index);
    });

    _loadIfNeeded(0);
  }

  void _loadIfNeeded(int tabIndex) {
    if (!mounted) return;
    if (_loadedTabs.contains(tabIndex)) return;
    final cubit = context.read<FriendListCubit>();
    switch (tabIndex) {
      case 0:
        _loadedTabs.add(tabIndex);
        cubit.loadFriends();
      case 1:
        _loadedTabs.add(tabIndex);
        cubit.loadReceivedRequests();
      case 2:
        _loadedTabs.add(tabIndex);
    }
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
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Bạn bè'),
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        backgroundColor: theme.colorScheme.surface,
        surfaceTintColor: theme.colorScheme.surface,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: BlocBuilder<FriendListCubit, FriendListData>(
              buildWhen: (prev, curr) =>
                  curr is FriendListLoaded &&
                  (prev is! FriendListLoaded ||
                      prev.unreadRequestCount != curr.unreadRequestCount),
              builder: (context, state) {
                if (state is! FriendListLoaded) {
                  return const SizedBox.shrink();
                }
                final unreadCount = state.unreadRequestCount;
                return Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.all(4),
                  child: TabBar(
                    controller: _tabController,
                    onTap: (_) => FocusScope.of(context).unfocus(),
                    dividerColor: Colors.transparent,
                    indicator: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.primary
                              .withValues(alpha: 0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelColor: theme.colorScheme.onPrimary,
                    unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
                    labelStyle: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    unselectedLabelStyle: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    tabs: [
                      const _PillTab(
                        icon: Icons.people_outline,
                        label: 'Bạn bè',
                      ),
                      _PillTab(
                        icon: unreadCount > 0
                            ? Icons.mark_email_unread_outlined
                            : Icons.mail_outline,
                        label: 'Lời mời',
                        count: unreadCount,
                      ),
                      const _PillTab(
                        icon: Icons.search,
                        label: 'Tìm kiếm',
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: TabBarView(
          controller: _tabController,
          children: const [
            FriendsListTab(),
            FriendRequestsTab(),
            SearchUsersTab(),
          ],
        ),
      ),
    );
  }
}

class _PillTab extends StatelessWidget {
  const _PillTab({
    required this.icon,
    required this.label,
    this.count = 0,
  });

  final IconData icon;
  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Tab(
      height: 48,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          if (count > 0) ...[
            const SizedBox(width: 5),
            _RequestBadge(count: count),
          ],
        ],
      ),
    );
  }
}

class _RequestBadge extends StatelessWidget {
  const _RequestBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
      decoration: BoxDecoration(
        color: const Color(0xFFE53935),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(
        count > 99 ? '99+' : '$count',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          height: 1,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
