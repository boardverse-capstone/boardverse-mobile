import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_icons.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/neo_brutalism_theme.dart';
import '../../../domain/entities/entities.dart';
import '../../cubit/cubit.dart';
import '../../widgets/widgets.dart';
import '../friend_profile_page.dart';

/// Neo-brutalism Tab "Tìm kiếm" — search box với debounce.
class SearchUsersTab extends StatefulWidget {
  const SearchUsersTab({super.key});

  @override
  State<SearchUsersTab> createState() => _SearchUsersTabState();
}

class _SearchUsersTabState extends State<SearchUsersTab> {
  final _searchController = TextEditingController();

  bool _isSearching = false;
  String _errorMessage = '';
  List<UserSearchEntity> _results = const [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    final query = value.trim();
    if (query.isEmpty) {
      setState(() {
        _results = const [];
        _isSearching = false;
        _errorMessage = '';
      });
      return;
    }
    _performSearch(query);
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
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Lỗi tìm kiếm: $e';
        _isSearching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.borderDark : AppColors.border;

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
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.radiusFull),
                border: Border.all(color: borderColor, width: NeoBrutalismTheme.borderWidth),
                boxShadow: NeoBrutalismTheme.lightShadow(
                  shadowColor: AppColors.black.withValues(alpha: 0.05),
                ),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                style: const TextStyle(fontWeight: FontWeight.w700),
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm theo tên người dùng...',
                  prefixIcon: const Icon(AppIcons.search, color: AppColors.primary),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(AppIcons.close, color: AppColors.textSecondary),
                          onPressed: () {
                            _searchController.clear();
                            _onSearchChanged('');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.md,
                  ),
                ),
              ),
            ),
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isSearching) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
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
    });

    try {
      await context.read<FriendListCubit>().sendFriendRequest(
            addresseeId: user.odId,
          );
      messenger.showSnackBar(
        SnackBar(
          content: Text('Đã gửi lời mời đến ${user.username}'),
          backgroundColor: AppColors.success,
        ),
      );
      _performSearch(_searchController.text);
    } catch (e) {
      if (mounted) {
        setState(() {
          _results[index] = user;
        });
      }
      messenger.showSnackBar(
        SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  void _openProfile(BuildContext context, UserSearchEntity user) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FriendProfilePage(userId: user.odId),
      ),
    );
  }
}
