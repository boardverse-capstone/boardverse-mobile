import 'package:flutter/material.dart';

import 'package:boardverse/core/theme/app_shimmer.dart';
import 'package:boardverse/core/theme/app_spacing.dart';

/// Skeleton loading states dùng chung cho feature tournament — thay thế
/// `Center(child: CircularProgressIndicator())` để UX mượt hơn, đồng nhất
/// với các feature khác (lobby, matchmaking, wallet).
///
/// Tất cả widget trong file này dùng [AppShimmer] — base/highlight color
/// tự thích ứng theo theme sáng/tối.
class TournamentSkeleton {
  TournamentSkeleton._();

  // ─── List placeholders ──────────────────────────────────────────────

  /// Skeleton cho list tournament — mô phỏng [TournamentListCard]:
  /// - Ảnh thumbnail + 2 dòng text + status pill.
  static Widget listCard({double height = 140}) {
    return Builder(
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: AppShimmer.boxRadius(
          context: context,
          height: height,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  /// Stack nhiều [listCard] — dùng cho cả trang list trong khi fetch.
  static Widget list({int itemCount = 6}) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      itemCount: itemCount,
      itemBuilder: (_, _) => listCard(),
    );
  }

  // ─── Detail page placeholders ───────────────────────────────────────

  /// Skeleton cho header (gradient + title + meta) của tournament detail.
  static Widget detailHeader() {
    return Builder(
      builder: (context) => Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            Row(
              children: [
                AppShimmer.boxRadius(
                  context: context,
                  width: 56,
                  height: 56,
                  borderRadius: BorderRadius.circular(12),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppShimmer.box(
                        context: context,
                        height: 18,
                        borderRadius: 6,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      AppShimmer.box(
                        context: context,
                        width: 180,
                        height: 12,
                        borderRadius: 6,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                AppShimmer.boxRadius(
                  context: context,
                  width: 80,
                  height: 28,
                  borderRadius: BorderRadius.circular(20),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            AppShimmer.textLines(
              context: context,
              lines: 3,
              lineHeight: 12,
              lastLineWidth: 160,
            ),
          ],
        ),
      ),
    );
  }

  /// Skeleton body cho tournament detail — mô phỏng các card stack.
  static Widget detailBody() {
    return Builder(
      builder: (context) => ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        children: [
          AppShimmer.boxRadius(
            context: context,
            height: 120,
            borderRadius: BorderRadius.circular(16),
          ),
          const SizedBox(height: AppSpacing.md),
          AppShimmer.boxRadius(
            context: context,
            height: 180,
            borderRadius: BorderRadius.circular(16),
          ),
          const SizedBox(height: AppSpacing.md),
          AppShimmer.boxRadius(
            context: context,
            height: 96,
            borderRadius: BorderRadius.circular(16),
          ),
        ],
      ),
    );
  }

  /// Skeleton toàn trang detail — header + body.
  static Widget detailPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        detailHeader(),
        const Divider(height: 1),
        Expanded(child: detailBody()),
      ],
    );
  }

  // ─── Match detail placeholder ───────────────────────────────────────

  /// Skeleton cho match detail page — header + 2 player rows + footer.
  static Widget matchDetail() {
    return Builder(
      builder: (context) => ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          AppShimmer.boxRadius(
            context: context,
            height: 80,
            borderRadius: BorderRadius.circular(16),
          ),
          const SizedBox(height: AppSpacing.md),
          AppShimmer.listItem(context: context, avatarSize: 56),
          AppShimmer.listItem(context: context, avatarSize: 56),
          const SizedBox(height: AppSpacing.md),
          AppShimmer.boxRadius(
            context: context,
            height: 96,
            borderRadius: BorderRadius.circular(16),
          ),
        ],
      ),
    );
  }

  // ─── Participant detail placeholder ────────────────────────────────

  /// Skeleton cho participant detail page — avatar lớn + stats + rating.
  static Widget participantDetail() {
    return Builder(
      builder: (context) => ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Center(
            child: AppShimmer.circle(context: context, size: 96),
          ),
          const SizedBox(height: AppSpacing.md),
          Center(
            child: AppShimmer.box(
              context: context,
              width: 180,
              height: 18,
              borderRadius: 6,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Center(
            child: AppShimmer.box(
              context: context,
              width: 120,
              height: 12,
              borderRadius: 6,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppShimmer.boxRadius(
            context: context,
            height: 100,
            borderRadius: BorderRadius.circular(16),
          ),
          const SizedBox(height: AppSpacing.md),
          AppShimmer.boxRadius(
            context: context,
            height: 160,
            borderRadius: BorderRadius.circular(16),
          ),
        ],
      ),
    );
  }

  // ─── Bottom sheet placeholder ──────────────────────────────────────

  /// Skeleton cho bottom sheet detail — header + content body.
  static Widget detailSheet() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        detailHeader(),
        const Divider(height: 1),
        Flexible(child: detailBody()),
      ],
    );
  }
}
