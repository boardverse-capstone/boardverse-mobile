import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/theme/app_icons.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../domain/entities/entities.dart';
import '../../cubit/friend_list_cubit.dart';
import '../../widgets/shared/common_widgets.dart';
import '../../widgets/user_search_card.dart';
import '../friend_profile_page.dart';

/// Tab "Tìm kiếm" — search box + debounce 400ms + kết quả realtime.
///
/// Logic UI tách riêng khỏi FriendsListTab và FriendRequestsTab vì có
/// state riêng (search controller, debounce timer, optimistic update khi
/// gửi request).
class SearchUsersTab extends StatefulWidget {
  const SearchUsersTab({super.key});

  @override
  State<SearchUsersTab> createState() => _SearchUsersTabState();
}

class _SearchUsersTabState extends State<SearchUsersTab> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  /// Track ID đang gửi request để UI biết spinner/optimistic update.
  final Set<String> _sendingIds = <String>{};

  bool _isSearching = false;
  String _errorMessage = '';
  List<UserSearchEntity> _results = const [];

  @override
  void initState() {
    super.initState();
    // Listener để suffix IconButton (× clear) cập nhật khi user gõ.
    _searchController.addListener(() => setState(() {}));
  }

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

  /// Optimistic update: user gửi request → UI đổi nút thành "Đã gửi" ngay.
  /// Rollback nếu API lỗi.
  Future<void> _sendRequest(UserSearchEntity user) async {
    final messenger = ScaffoldMessenger.of(context);
    final index = _results.indexWhere((u) => u.odId == user.odId);
    if (index == -1) return;

    setState(() {
      _results[index] = UserSearchEntity(
        odId: user.odId,
        username: user.username,
        avatarUrl: user.avatarUrl,
        karmaPoints: user.karmaPoints,
        friendshipStatus: FriendshipStatus.pendingSent,
        mutualFriendsCount: user.mutualFriendsCount,
      );
      _sendingIds.add(user.odId);
    });

    try {
      await context.read<FriendListCubit>().sendFriendRequest(
            addresseeId: user.odId,
          );
      messenger.showSnackBar(
        SnackBar(content: Text('Đã gửi lời mời đến ${user.username}')),
      );
      _performSearch(_searchController.text);
    } on Object catch (e) {
      if (mounted) {
        setState(() {
          _results[index] = user;
        });
      }
      messenger.showSnackBar(
        SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() {
          _sendingIds.remove(user.odId);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      top: false,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.xs,
            ),
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
          Expanded(child: _buildBody(theme)),
        ],
      ),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage.isNotEmpty) {
      return ErrorRetryView(
        message: _errorMessage,
        onRetry: () => _performSearch(_searchController.text),
      );
    }
    if (_results.isEmpty) {
      final hasQuery = _searchController.text.trim().isNotEmpty;
      return EmptyState(
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
          onTap: () => _openProfile(context, user),
          onSendRequest: (user.friendshipStatus == FriendshipStatus.none ||
                  user.friendshipStatus == null)
              ? () => _sendRequest(user)
              : null,
        );
      },
    );
  }

  void _openProfile(BuildContext context, UserSearchEntity user) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FriendProfilePage(userId: user.odId),
      ),
    );
  }
}
