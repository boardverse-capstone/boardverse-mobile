import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../domain/entities/entities.dart';
import '../../cubit/friend_list_cubit.dart';
import '../../cubit/friend_list_state.dart';
import '../../widgets/friend_request_card.dart';
import '../../widgets/shared/common_widgets.dart';
import '../../widgets/shared/time_ago.dart';

/// Tab "Lời mời" — gồm 2 phần: received (inbox) + sent (outbox).
class FriendRequestsTab extends StatelessWidget {
  const FriendRequestsTab({super.key});

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
          final received = state.receivedRequests;
          final sent = state.sentRequests;
          if (received.isEmpty && sent.isEmpty) {
            return const EmptyState(
              icon: Icons.mark_email_read_outlined,
              title: 'Không có lời mời nào',
              subtitle: 'Các lời mời kết bạn sẽ hiển thị ở đây.',
            );
          }
          return RefreshIndicator(
            onRefresh: () =>
                context.read<FriendListCubit>().refreshFriends(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                if (received.isNotEmpty) ...[
                  SectionTitle(
                    title: 'Lời mời đã nhận',
                    count: received.length,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  for (var i = 0; i < received.length; i++) ...[
                    if (i > 0) const SizedBox(height: AppSpacing.sm),
                    FriendRequestCard(
                      request: received[i],
                      onAccept: () =>
                          _acceptRequest(context, received[i].requestId),
                      onDecline: () =>
                          _declineRequest(context, received[i].requestId),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                ],
                if (sent.isNotEmpty) ...[
                  SectionTitle(
                    title: 'Đã gửi',
                    count: sent.length,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  for (var i = 0; i < sent.length; i++) ...[
                    if (i > 0) const SizedBox(height: AppSpacing.sm),
                    SentRequestTile(request: sent[i]),
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

/// Tile hiển thị 1 request trong phần "Đã gửi" — read-only, không có
/// action button, chỉ hiển thị tên + time + badge "Đang chờ".
class SentRequestTile extends StatelessWidget {
  const SentRequestTile({super.key, required this.request});

  final FriendRequestEntity request;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return OutlinedCard(
      child: ListTile(
        leading: UserAvatar(
          username: request.requesterName,
          avatarUrl: request.requesterAvatar,
        ),
        title: Text(request.requesterName),
        subtitle: Text(
          'Đã gửi ${formatTimeAgo(request.createdAt)} • Đang chờ',
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
