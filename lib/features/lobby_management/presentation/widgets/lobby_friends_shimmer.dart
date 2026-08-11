import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';

/// Shimmer skeleton cho danh sách bạn bè trong FriendsSheet.
///
/// Hiển thị khi LobbyCubit đang emit [LobbyFriendsLoading]. Mỗi skeleton
/// tile mô phỏng đúng layout của OnlineFriendsList (avatar tròn + 2 dòng
/// text + nút "Mời" / "Đã mời") để tránh "flash" khi data load xong.
class LobbyFriendsShimmer extends StatelessWidget {
  final int itemCount;
  final bool shrinkWrap;

  const LobbyFriendsShimmer({
    super.key,
    this.itemCount = 6,
    this.shrinkWrap = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      // Mặc định không scroll — FriendsSheet bọc trong
      // DraggableScrollableSheet, cần cho DraggableScrollableSheet kiểm
      // soát scroll. Khi dùng ngoài sheet (vd BookingsPage tab loading),
      // truyền `shrinkWrap: true` để cho phép cuộn cùng parent scroll.
      physics: shrinkWrap
          ? const NeverScrollableScrollPhysics()
          : const NeverScrollableScrollPhysics(),
      shrinkWrap: shrinkWrap,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      itemCount: itemCount,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (_, _) => const _FriendTileSkeleton(),
    );
  }
}

class _FriendTileSkeleton extends StatelessWidget {
  const _FriendTileSkeleton();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppShimmer.shimmer(
      context: context,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AppRadius.radiusLgAll,
          border: Border.all(
            color: theme.colorScheme.outlineVariant,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            // Avatar tròn 48dp
            AppShimmer.circle(context: context, size: 48),
            const SizedBox(width: AppSpacing.md),
            // Text placeholders
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tên — full width
                  Container(
                    width: double.infinity,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  // Username — ngắn hơn
                  Container(
                    width: 140,
                    height: 11,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            // Nút "Mời" placeholder
            Container(
              width: 76,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
