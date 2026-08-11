import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../domain/entities/entities.dart';
import '../../cubit/cubit.dart';
import '../../widgets/widgets.dart';
import '../friend_profile_page.dart';

/// Neo-brutalism Tab "Bạn bè".
///
/// Bug fix (Aug 2026):
/// - Trước đây cubit emit `FriendListError` (state tổng) khi load lỗi → phá
///   hủy toàn bộ dữ liệu đã load ở các section khác. Khi user chuyển tab
///   qua lại, dữ liệu hiển thị "không tìm thấy bạn bè" dù list đã load
///   thành công trước đó.
/// - Bây giờ cubit giữ `FriendListLoaded` và set `friendsError` /
///   `receivedRequestsError` cho section tương ứng. UI mỗi tab tự check
///   error riêng và hiển thị retry button, trong khi vẫn giữ nguyên data
///   đã load.
class FriendsListTab extends StatelessWidget {
  const FriendsListTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FriendListCubit, FriendListData>(
      builder: (context, state) {
        // Tab này đang ở friends section.
        if (state is FriendListLoading || state is FriendListInitial) {
          // Chưa load lần nào → loading.
          if (state is FriendListInitial) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }
        }

        // FriendListLoaded có thể có hoặc chưa có friends data.
        if (state is FriendListLoaded) {
          // Section friends đang loading + chưa từng load → spinner.
          if (state.friendsLoading && !state.friendsEverLoaded) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          // Section friends load lỗi + chưa có data cũ → hiển thị retry
          // (không phá hủy data ở section khác).
          if (state.friendsError != null && state.friends.isEmpty) {
            return ErrorRetryView(
              message: state.friendsError!,
              onRetry: () => context.read<FriendListCubit>().loadFriends(),
            );
          }

          // Section friends đã load nhưng list rỗng → empty state.
          if (state.friends.isEmpty) {
            return RefreshIndicator(
              onRefresh: () =>
                  context.read<FriendListCubit>().refreshFriends(),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                children: [
                  const SizedBox(height: AppSpacing.xxxl),
                  const EmptyState(
                    icon: Icons.people_outline,
                    title: 'Chưa có bạn bè nào',
                    subtitle:
                        'Hãy chuyển sang tab "Tìm kiếm" để gửi lời mời kết bạn.',
                  ),
                ],
              ),
            );
          }

          // Section friends có data → hiển thị list.
          return RefreshIndicator(
            onRefresh: () =>
                context.read<FriendListCubit>().refreshFriends(),
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                AppSpacing.md,
              ),
              itemCount: state.friends.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) {
                final friend = state.friends[index];
                return FriendCard(
                  friend: friend,
                  onTap: () => _openProfile(context, friend),
                  onInviteToLobby: () => _showInviteSnack(context, friend),
                );
              },
            ),
          );
        }

        // Fallback cho các state không mong đợi.
        return const SizedBox.shrink();
      },
    );
  }

  void _showInviteSnack(BuildContext context, FriendEntity friend) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Đã gửi lời mời đến ${friend.username}')),
    );
  }

  void _openProfile(BuildContext context, FriendEntity friend) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FriendProfilePage(userId: friend.odId),
      ),
    );
  }
}
