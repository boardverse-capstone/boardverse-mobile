import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../domain/entities/entities.dart';
import '../../cubit/cubit.dart';
import '../../widgets/widgets.dart';
import '../friend_profile_page.dart';

/// Tab "Bạn bè" — displays friends list (Accepted status) in a list view.
class FriendsListTab extends StatelessWidget {
  const FriendsListTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FriendListCubit, FriendListData>(
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
