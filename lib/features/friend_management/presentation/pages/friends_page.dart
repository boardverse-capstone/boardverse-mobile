import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/neo_brutalism_theme.dart';
import '../cubit/cubit.dart';
import 'tabs/friend_requests_tab.dart';
import 'tabs/friends_list_tab.dart';
import 'tabs/search_users_tab.dart';

/// Neo-brutalism Main Friends page with 3 tabs.
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.backgroundDark : AppColors.background;
    final borderColor = isDark ? AppColors.borderDark : AppColors.border;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        title: const Text(
          'BẠN BÈ',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
        centerTitle: true,
        scrolledUnderElevation: 0.5,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
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
                    color: isDark ? AppColors.surfaceDark : AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: borderColor,
                      width: NeoBrutalismTheme.borderWidth,
                    ),
                    boxShadow: NeoBrutalismTheme.lightShadow(
                      shadowColor: AppColors.black.withValues(alpha: 0.05),
                    ),
                  ),
                  padding: const EdgeInsets.all(4),
                  child: TabBar(
                    controller: _tabController,
                    onTap: (_) => FocusScope.of(context).unfocus(),
                    dividerColor: Colors.transparent,
                    indicator: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.black, width: 1.5),
                      boxShadow: const [
                        BoxShadow(
                          color: AppColors.black,
                          blurRadius: 0,
                          offset: Offset(2, 2),
                        ),
                      ],
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelColor: AppColors.white,
                    unselectedLabelColor: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondary,
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                      letterSpacing: 0.5,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      letterSpacing: 0.5,
                    ),
                    tabs: [
                      const _PillTab(
                        icon: Icons.people_outline,
                        label: 'BẠN BÈ',
                      ),
                      _PillTab(
                        icon: unreadCount > 0
                            ? Icons.mark_email_unread_outlined
                            : Icons.mail_outline,
                        label: 'LỜI MỜI',
                        count: unreadCount,
                      ),
                      const _PillTab(
                        icon: Icons.search,
                        label: 'TÌM KIẾM',
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
          Icon(icon, size: 16),
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
        color: AppColors.error,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: AppColors.black, width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: AppColors.black,
            blurRadius: 0,
            offset: Offset(1, 1),
          ),
        ],
      ),
      child: Text(
        count > 99 ? '99+' : '$count',
        style: const TextStyle(
          color: AppColors.white,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          height: 1,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}