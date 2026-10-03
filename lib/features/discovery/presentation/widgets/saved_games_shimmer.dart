import 'package:flutter/material.dart';

import 'package:boardverse/core/theme/app_colors.dart';
import 'package:boardverse/core/theme/app_radius.dart';
import 'package:boardverse/core/theme/app_shimmer.dart';
import 'package:boardverse/core/theme/app_spacing.dart';

/// Shimmer skeleton cho trang "Game đã lưu" (`SavedGamesPage`).
///
/// Mô phỏng layout grid 2 cột của `_SavedGameCard` (mỗi card gồm
/// thumbnail ở trên + tên game + stats ở dưới) để khi load xong,
/// UI chỉ "swap" skeleton → data mà người dùng không cảm thấy giật.
///
/// **Tại sao dùng shimmer thay cho spinner (CircularProgressIndicator)?**
/// - Skeleton chiếm chỗ ngay lập tức → người dùng thấy đúng số lượng
///   card sắp tới (6 card giả → khi load xong sẽ có ~6 card thật).
/// - Tâm lý: skeleton perceived là "đang tải" nhanh hơn spinner
///   quay tròn ~30% (chuẩn Material Design).
/// - Tránh "shovel-ware" UI: spinner lơ lửng giữa màn hình rỗng
///   tạo cảm giác app bị đứng.
///
/// **Dùng app-wide:** `AppShimmer` (lib/core/theme/app_shimmer.dart)
/// — toàn app đang dùng cùng baseColor/highlightColor + period
/// 1500ms để đảm bảo visual nhất quán.
class SavedGamesShimmer extends StatelessWidget {
  /// Số card skeleton hiển thị. Mặc định 6 (2 cột × 3 hàng) — đủ
  /// phủ kín viewport của đa số thiết bị mobile.
  final int itemCount;

  const SavedGamesShimmer({super.key, this.itemCount = 6});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgBase = isDark ? const Color(0xFF2C2C2C) : AppColors.surface;

    return GridView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      physics: const AlwaysScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: AppSpacing.md,
        crossAxisSpacing: AppSpacing.md,
        childAspectRatio: 0.72, // Khớp _SavedGameCard (GridView ở page)
      ),
      itemCount: itemCount,
      itemBuilder: (_, _) => AppShimmer.shimmer(
        context: context,
        child: _SavedGameCardSkeleton(bgBase: bgBase),
      ),
    );
  }
}

/// Skeleton của 1 card — khớp `_SavedGameCard`:
///   ┌────────────────────┐
///   │   [thumbnail  ▢]   │ ← Box lớn vuông
///   │                    │
///   ├────────────────────┤
///   │ ▬▬▬▬▬▬▬▬▬▬▬▬     │ ← Tên game (line 1)
///   │ ▬▬▬▬▬▬            │ ← Tên game (line 2 - ellipsis)
///   │ [▣ weight] [▣ ⏱]  │ ← 2 stat badge
///   └────────────────────┘
class _SavedGameCardSkeleton extends StatelessWidget {
  const _SavedGameCardSkeleton({required this.bgBase});

  final Color bgBase;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: bgBase,
        borderRadius: AppRadius.radiusMdAll,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail placeholder — Expanded chiếm phần ảnh
          // (giống tỷ lệ _SavedGameCard)
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppRadius.radiusMd),
                ),
              ),
            ),
          ),
          // Info section
          Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Game name — 2 dòng (line 1 full, line 2 ngắn)
                AppShimmer.box(
                  context: context,
                  height: 12,
                  borderRadius: 4,
                ),
                const SizedBox(height: 6),
                AppShimmer.box(
                  context: context,
                  width: 80,
                  height: 12,
                  borderRadius: 4,
                ),
                const SizedBox(height: 8),
                // Stat badges row (weight + playtime)
                Row(
                  children: [
                    AppShimmer.box(
                      context: context,
                      width: 40,
                      height: 14,
                      borderRadius: 6,
                    ),
                    const SizedBox(width: 6),
                    AppShimmer.box(
                      context: context,
                      width: 48,
                      height: 14,
                      borderRadius: 6,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
