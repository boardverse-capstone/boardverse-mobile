import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../domain/entities/entities.dart';
import '../../cubit/cubit.dart';
import '../../widgets/widgets.dart';
import '../friend_profile_page.dart';

/// Tab "Lời mời" — displays received friend requests (inbox).
class FriendRequestsTab extends StatelessWidget {
  const FriendRequestsTab({super.key});

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
          final received = state.receivedRequests;
          if (state.receivedRequestsLoading && received.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (received.isEmpty) {
            return RefreshIndicator(
              onRefresh: () => context
                  .read<FriendListCubit>()
                  .refreshReceivedRequests(),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                children: [
                  const SizedBox(height: AppSpacing.xxxl),
                  const EmptyState(
                    icon: Icons.mark_email_read_outlined,
                    title: 'Không có lời mời nào',
                    subtitle:
                        'Các lời mời kết bạn từ người khác sẽ hiển thị ở đây.',
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () =>
                context.read<FriendListCubit>().refreshReceivedRequests(),
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: received.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) {
                final request = received[index];
                return FriendRequestCard(
                  request: request,
                  onTap: () => _openRequesterProfile(context, request),
                  onAccept: () => _acceptRequest(context, request.requestId),
                  onDecline: () => _declineRequest(context, request.requestId),
                );
              },
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

  void _openRequesterProfile(
    BuildContext context,
    FriendRequestEntity request,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FriendProfilePage(userId: request.requesterId),
      ),
    );
  }
}
