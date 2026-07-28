import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../domain/entities/entities.dart';
import '../../cubit/friend_list_cubit.dart';
import '../../cubit/friend_list_state.dart';
import '../../widgets/friend_card.dart';
import '../../widgets/shared/common_widgets.dart';

/// Tab "Bạn bè" — hiển thị danh sách friend (status Accepted).
///
/// Logic: load → BlocBuilder render FriendsList | EmptyState | ErrorRetryView.
/// Pull-to-refresh qua RefreshIndicator.
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
          if (state.friends.isEmpty) {
            return const EmptyState(
              icon: Icons.people_outline,
              title: 'Chưa có bạn bè nào',
              subtitle:
                  'Hãy chuyển sang tab "Tìm kiếm" để gửi lời mời kết bạn.',
            );
          }
          return RefreshIndicator(
            onRefresh: () =>
                context.read<FriendListCubit>().refreshFriends(),
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: state.friends.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) {
                final friend = state.friends[index];
                return FriendCard(
                  friend: friend,
                  onUnfriend: () => _confirmUnfriend(context, friend),
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
