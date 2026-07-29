import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../cubit/friend_list_cubit.dart';
import '../cubit/friend_list_state.dart';
import 'tabs/friend_requests_tab.dart';
import 'tabs/friends_list_tab.dart';
import 'tabs/search_users_tab.dart';

/// Trang Friends với 3 tab con:
/// - Bạn bè (Friends) — [FriendsListTab]
/// - Lời mời (Friend Requests) — [FriendRequestsTab]
/// - Tìm kiếm (Search Users) — [SearchUsersTab]
///
/// Được mở từ Profile → "Bạn bè". Scaffold chỉ giữ AppBar + TabBar;
/// logic/business từng tab nằm trong file `pages/tabs/`.
///
/// **Loading strategy (per-tab, lazy):**
/// - KHÔNG gọi API nào khi mount — chờ user chuyển sang tab nào thì fetch
///   data của tab đó. Tránh tình trạng mở FriendsPage đã gọi 3 endpoints
///   trong khi user chỉ xem 1 tab.
/// - Tab "Bạn bè" → `loadFriends()` (1 API).
/// - Tab "Lời mời" → `loadReceivedRequests()` (1 API).
/// - Tab "Tìm kiếm" → on-demand qua debounce, gọi `searchUsers(query)`.
///
/// **Redesign UX:**
/// - Badge unread đặt trực tiếp cạnh nhãn "Lời mời" trong TabBar, không dùng
///   AppBar action riêng.
/// - TabBar đơn giản, icon nhỏ, label rõ ràng trên mobile.
class FriendsPage extends StatelessWidget {
  const FriendsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<FriendListCubit>(),
      child: const FriendsScaffold(),
    );
  }
}

class FriendsScaffold extends StatefulWidget {
  const FriendsScaffold({super.key});

  @override
  State<FriendsScaffold> createState() => _FriendsScaffoldState();
}

class _FriendsScaffoldState extends State<FriendsScaffold>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  /// Track tab nào đã load lần đầu — tránh gọi API nhiều lần khi user
  /// switch qua switch lại.
  final Set<int> _loadedTabs = <int>{};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      _loadIfNeeded(_tabController.index);
    });

    // Tab "Bạn bè" (index 0) là default — trigger load ngay.
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
        // Search tab — không preset data, search on-demand.
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
      appBar: AppBar(
        title: const Text('Bạn bè'),
        centerTitle: true,
        forceMaterialTransparency: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: BlocBuilder<FriendListCubit, FriendListState>(
            buildWhen: (prev, curr) =>
                curr is FriendListLoaded &&
                (prev is! FriendListLoaded ||
                    prev.unreadRequestCount != curr.unreadRequestCount),
            builder: (context, state) {
              final unreadCount = state is FriendListLoaded
                  ? state.unreadRequestCount
                  : 0;
              return TabBar(
                controller: _tabController,
                labelColor: theme.colorScheme.primary,
                unselectedLabelColor: theme.colorScheme.outline,
                indicatorColor: theme.colorScheme.primary,
                indicatorWeight: 3,
                labelStyle: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                unselectedLabelStyle: theme.textTheme.titleSmall,
                tabs: [
                  Tab(
                    icon: const Icon(Icons.people_outline, size: 22),
                    text: 'Bạn bè',
                    iconMargin: const EdgeInsets.only(bottom: 2),
                  ),
                  _TabWithBadge(
                    label: 'Lời mời',
                    count: unreadCount,
                  ),
                  const Tab(
                    icon: Icon(Icons.search, size: 22),
                    text: 'Tìm kiếm',
                    iconMargin: EdgeInsets.only(bottom: 2),
                  ),
                ],
              );
            },
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

/// Tab widget với badge count nhỏ nằm cạnh label.
/// Dùng cho tab "Lời mời" để hiển thị số request chưa đọc.
class _TabWithBadge extends StatelessWidget {
  const _TabWithBadge({
    required this.label,
    required this.count,
  });

  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            count > 0
                ? Icons.mark_email_unread_outlined
                : Icons.mail_outline,
            size: 22,
          ),
          const SizedBox(width: 6),
          Text(label),
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
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
      decoration: BoxDecoration(
        color: theme.colorScheme.error,
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
