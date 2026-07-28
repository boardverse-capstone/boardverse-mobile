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
class FriendsPage extends StatelessWidget {
  const FriendsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<FriendListCubit>()..loadFriends(),
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        final cubit = context.read<FriendListCubit>();
        if (_tabController.index == 0) cubit.loadFriends();
      }
    });
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
        actions: [_UnreadBadge(tabController: _tabController)],
        bottom: TabBar(
          controller: _tabController,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: theme.colorScheme.outline,
          indicatorColor: theme.colorScheme.primary,
          indicatorWeight: 3,
          labelStyle: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          tabs: const [
            Tab(icon: Icon(Icons.people_outline), text: 'Bạn bè'),
            Tab(icon: Icon(Icons.mark_email_unread_outlined), text: 'Lời mời'),
            Tab(icon: Icon(Icons.search), text: 'Tìm kiếm'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          FriendsListTab(),
          FriendRequestsTab(),
          SearchUsersTab(),
        ],
      ),
    );
  }
}

/// Badge đỏ hiển thị số friend request chưa đọc, đặt ở AppBar action.
class _UnreadBadge extends StatelessWidget {
  const _UnreadBadge({required this.tabController});

  final TabController tabController;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocBuilder<FriendListCubit, FriendListState>(
      buildWhen: (prev, curr) =>
          curr is FriendListLoaded &&
          (prev is! FriendListLoaded ||
              prev.unreadRequestCount != curr.unreadRequestCount),
      builder: (context, state) {
        final count = state is FriendListLoaded ? state.unreadRequestCount : 0;
        return Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.mail_outline),
              tooltip: 'Lời mời',
              onPressed: () => tabController.animateTo(1),
            ),
            if (count > 0)
              Positioned(
                right: 8,
                top: 8,
                child: _Badge(count: count, theme: theme),
              ),
          ],
        );
      },
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.count, required this.theme});

  final int count;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.error,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        count > 99 ? '99+' : '$count',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
