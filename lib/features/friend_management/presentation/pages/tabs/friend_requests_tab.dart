import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../domain/entities/entities.dart';
import '../../cubit/cubit.dart';
import '../../widgets/widgets.dart';
import '../friend_profile_page.dart';

/// Neo-brutalism Tab "Lời mời".
///
/// Bug fix (Aug 2026):
/// - Sử dụng `receivedRequestsError` riêng thay vì state `FriendListError`
///   tổng để không phá hủy dữ liệu của section khác khi user chuyển tab.
class FriendRequestsTab extends StatelessWidget {
  const FriendRequestsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FriendListCubit, FriendListData>(
      builder: (context, state) {
        if (state is FriendListLoaded) {
          final received = state.receivedRequests;

          // Section requests đang loading + chưa từng load → spinner.
          if (state.receivedRequestsLoading && !state.receivedRequestsEverLoaded) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          // Section requests load lỗi + chưa có data cũ → retry button.
          if (state.receivedRequestsError != null && received.isEmpty) {
            return ErrorRetryView(
              message: state.receivedRequestsError!,
              onRetry: () =>
                  context.read<FriendListCubit>().loadReceivedRequests(),
            );
          }

          // Section requests đã load nhưng rỗng → empty state.
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

        // FriendListInitial/Loading → spinner.
        return const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        );
      },
    );
  }

  void _acceptRequest(BuildContext context, String requestId) {
    context.read<FriendListCubit>().acceptFriendRequest(requestId);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã chấp nhận lời mời'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _declineRequest(BuildContext context, String requestId) {
    context.read<FriendListCubit>().declineFriendRequest(requestId);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã từ chối lời mời'),
        backgroundColor: AppColors.textSecondary,
      ),
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
