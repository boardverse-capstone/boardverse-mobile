import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../domain/entities/entities.dart';
import '../../cubit/friend_list_cubit.dart';
import '../../cubit/friend_list_state.dart';
import '../../widgets/friend_card.dart';
import '../../widgets/shared/common_widgets.dart';
import '../friend_profile_page.dart';

/// Tab "Bạn bè" — hiển thị danh sách friend (status Accepted) dạng grid vuông.
///
/// Redesign mobile-first: FriendCard vuông lớn hiển thị avatar rõ,
///
/// Logic: load → BlocBuilder render GridView | EmptyState | ErrorRetryView.
/// Pull-to-refresh qua RefreshIndicator.
/// Chỉ loading spinner khi slice `friends` đang fetch (per-tab flag).
class FriendsListTab extends StatelessWidget {
  const FriendsListTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FriendListCubit, FriendListState>(
      builder: (context, state) {
        if (state is FriendListLoading || state is FriendListInitial) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is FriendListError) {
          return ErrorRetryView(
            message: state.message,
            onRetry: () => context.read<FriendListCubit>().loadFriends(),
          );
        }
        if (state is FriendListLoaded) {
          // Per-tab loading: chỉ hiển thị spinner khi slice `friends` đang
          // fetch và chưa có data trước đó.
          if (state.friendsLoading && state.friends.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
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
          return RefreshIndicator(
            onRefresh: () =>
                context.read<FriendListCubit>().refreshFriends(),
            child: GridView.builder(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.all(AppSpacing.md),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.70,
                crossAxisSpacing: AppSpacing.sm,
                mainAxisSpacing: AppSpacing.sm,
              ),
              itemCount: state.friends.length,
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
