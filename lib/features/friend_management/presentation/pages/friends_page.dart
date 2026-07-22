import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/friend_entity.dart';
import '../cubit/friend_list_cubit.dart';
import '../cubit/friend_list_state.dart';
import '../widgets/friend_card.dart';
import '../widgets/friend_request_card.dart';
import '../widgets/user_search_card.dart';

/// Trang Friends với 3 tab con:
/// - Bạn bè (Friends)
/// - Lời mời (Friend Requests)
/// - Tìm kiếm (Search Users)
///
/// Được mở từ Profile → "Bạn bè".
class FriendsPage extends StatelessWidget {
  const FriendsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<FriendListCubit>()..loadFriends(),
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      // Re-fetch when user switches to a different tab
      if (!_tabController.indexIsChanging) {
        final cubit = context.read<FriendListCubit>();
        if (_tabController.index == 0) {
          cubit.loadFriends();
        }
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
        actions: [
          BlocBuilder<FriendListCubit, FriendListState>(
            buildWhen: (prev, curr) =>
                curr is FriendListLoaded &&
                (prev is! FriendListLoaded ||
                    prev.unreadRequestCount != curr.unreadRequestCount),
            builder: (context, state) {
              final count = state is FriendListLoaded
                  ? state.unreadRequestCount
                  : 0;
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.mail_outline),
                    tooltip: 'Lời mời',
                    onPressed: () => _tabController.animateTo(1),
                  ),
                  if (count > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
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
                      ),
                    ),
                ],
              );
            },
          ),
        ],
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
            Tab(
              icon: Icon(Icons.mark_email_unread_outlined),
              text: 'Lời mời',
            ),
            Tab(icon: Icon(AppIcons.search), text: 'Tìm kiếm'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _FriendsListTab(),
          _FriendRequestsTab(),
          _SearchUsersTab(),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Tab 1: Friends List
// ═══════════════════════════════════════════════════════════════════════════

class _FriendsListTab extends StatelessWidget {
  const _FriendsListTab();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FriendListCubit, FriendListState>(
      builder: (context, state) {
        if (state is FriendListLoading || state is FriendListInitial) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is FriendListError) {
          return _ErrorView(
            message: state.message,
            onRetry: () => context.read<FriendListCubit>().loadFriends(),
          );
        }

        if (state is FriendListLoaded) {
          if (state.friends.isEmpty) {
            return _EmptyView(
              icon: Icons.people_outline,
              title: 'Chưa có bạn bè nào',
              subtitle:
                  'Hãy chuyển sang tab "Tìm kiếm" để gửi lời mời kết bạn.',
            );
          }

          return RefreshIndicator(
            onRefresh: () => context.read<FriendListCubit>().refreshFriends(),
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: state.friends.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) {
                final friend = state.friends[index];
                return FriendCard(
                  friend: friend,
                  onUnfriend: () => _confirmUnfriend(context, friend),
                  onInviteToLobby: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Đã gửi lời mời đến ${friend.username}'),
                      ),
                    );
                  },
                );
              },
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  void _confirmUnfriend(BuildContext context, FriendEntity friend) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hủy kết bạn'),
        content: Text('Bạn có chắc muốn hủy kết bạn với ${friend.username}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Hủy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<FriendListCubit>().unfriend(friend.odId);
            },
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Tab 2: Friend Requests
// ═══════════════════════════════════════════════════════════════════════════

class _FriendRequestsTab extends StatelessWidget {
  const _FriendRequestsTab();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FriendListCubit, FriendListState>(
      builder: (context, state) {
        if (state is FriendListLoading || state is FriendListInitial) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is FriendListError) {
          return _ErrorView(
            message: state.message,
            onRetry: () => context.read<FriendListCubit>().loadFriends(),
          );
        }

        if (state is FriendListLoaded) {
          final received = state.receivedRequests;
          final sent = state.sentRequests;

          if (received.isEmpty && sent.isEmpty) {
            return _EmptyView(
              icon: Icons.mark_email_read_outlined,
              title: 'Không có lời mời nào',
              subtitle: 'Các lời mời kết bạn sẽ hiển thị ở đây.',
            );
          }

          return RefreshIndicator(
            onRefresh: () => context.read<FriendListCubit>().refreshFriends(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                if (received.isNotEmpty) ...[
                  _SectionTitle(
                    title: 'Lời mời đã nhận',
                    count: received.length,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  for (var i = 0; i < received.length; i++) ...[
                    if (i > 0) const SizedBox(height: AppSpacing.sm),
                    FriendRequestCard(
                      request: received[i],
                      onAccept: () => _acceptRequest(context, received[i].requestId),
                      onDecline: () =>
                          _declineRequest(context, received[i].requestId),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                ],
                if (sent.isNotEmpty) ...[
                  _SectionTitle(
                    title: 'Đã gửi',
                    count: sent.length,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  for (var i = 0; i < sent.length; i++) ...[
                    if (i > 0) const SizedBox(height: AppSpacing.sm),
                    _SentRequestTile(request: sent[i]),
                  ],
                ],
              ],
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  void _acceptRequest(BuildContext context, String requestId) {
    context.read<FriendListCubit>().acceptFriendRequest(requestId);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã chấp nhận lời mời')),
    );
  }

  void _declineRequest(BuildContext context, String requestId) {
    context.read<FriendListCubit>().declineFriendRequest(requestId);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã từ chối lời mời')),
    );
  }
}

class _SentRequestTile extends StatelessWidget {
  const _SentRequestTile({required this.request});

  final FriendRequestEntity request;

  String _formatTimeAgo() {
    final diff = DateTime.now().difference(request.createdAt);
    if (diff.inDays > 0) return '${diff.inDays} ngày trước';
    if (diff.inHours > 0) return '${diff.inHours} giờ trước';
    if (diff.inMinutes > 0) return '${diff.inMinutes} phút trước';
    return 'Vừa gửi';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasImage = request.requesterAvatar.isNotEmpty &&
        request.requesterAvatar.startsWith('http');

    return Material(
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
        borderRadius: BorderRadius.circular(AppRadius.radiusMd),
      ),
      borderRadius: BorderRadius.circular(AppRadius.radiusMd),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          backgroundImage:
              hasImage ? NetworkImage(request.requesterAvatar) : null,
          onBackgroundImageError: hasImage ? (_, _) {} : null,
          child: hasImage
              ? null
              : Text(
                  request.requesterName.isNotEmpty
                      ? request.requesterName[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
        ),
        title: Text(request.requesterName),
        subtitle: Text(
          'Đã gửi ${_formatTimeAgo()} • Đang chờ',
          style: theme.textTheme.bodySmall,
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'Đang chờ',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Tab 3: Search Users
// ═══════════════════════════════════════════════════════════════════════════

class _SearchUsersTab extends StatefulWidget {
  const _SearchUsersTab();

  @override
  State<_SearchUsersTab> createState() => _SearchUsersTabState();
}

class _SearchUsersTabState extends State<_SearchUsersTab> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  bool _isSearching = false;
  String _errorMessage = '';
  List<UserSearchEntity> _results = const [];

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    final query = value.trim();
    if (query.isEmpty) {
      setState(() {
        _results = const [];
        _isSearching = false;
        _errorMessage = '';
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _performSearch(query);
    });
  }

  Future<void> _performSearch(String query) async {
    setState(() {
      _isSearching = true;
      _errorMessage = '';
    });
    try {
      final results = await context.read<FriendListCubit>().searchUsers(query);
      if (!mounted) return;
      setState(() {
        _results = results;
        _isSearching = false;
      });
    } on Object catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Lỗi tìm kiếm: $e';
        _isSearching = false;
      });
    }
  }

  Future<void> _sendRequest(UserSearchEntity user) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await context.read<FriendListCubit>().sendFriendRequest(
            addresseeId: user.odId,
          );
      messenger.showSnackBar(
        SnackBar(content: Text('Đã gửi lời mời đến ${user.username}')),
      );
      // Refresh search results
      _performSearch(_searchController.text);
    } on Object catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Tìm kiếm theo tên người dùng...',
              prefixIcon: const Icon(AppIcons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(AppIcons.close),
                      onPressed: () {
                        _searchController.clear();
                        _onSearchChanged('');
                      },
                    )
                  : null,
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerHighest,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.radiusFull),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        Expanded(
          child: _buildBody(theme),
        ),
      ],
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage.isNotEmpty) {
      return _ErrorView(
        message: _errorMessage,
        onRetry: () => _performSearch(_searchController.text),
      );
    }

    if (_results.isEmpty) {
      final hasQuery = _searchController.text.trim().isNotEmpty;
      return _EmptyView(
        icon: hasQuery ? Icons.search_off : AppIcons.search,
        title: hasQuery ? 'Không tìm thấy kết quả' : 'Tìm kiếm bạn bè',
        subtitle: hasQuery
            ? 'Thử tìm với từ khóa khác.'
            : 'Nhập tên người dùng để bắt đầu tìm kiếm.',
      );
    }

    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      itemCount: _results.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final user = _results[index];
        return UserSearchCard(
          user: user,
          onSendRequest: user.friendshipStatus == FriendshipStatus.none
              ? () => _sendRequest(user)
              : null,
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Shared widgets
// ═══════════════════════════════════════════════════════════════════════════

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.count});

  final String title;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      child: Row(
        children: [
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          if (count != null) ...[
            const SizedBox(width: AppSpacing.xs),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 48,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(AppIcons.refresh),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}