import 'package:flutter/material.dart';

import 'package:boardverse_mobile/core/theme/theme.dart';

/// Shimmer skeleton cho LobbyInvitesPage — hiển thị khi
/// `LobbyInviteCubit` đang emit `LobbyInviteLoading`. Mỗi tile mô phỏng
/// layout của LobbyInviteCard (avatar + 2 dòng text + action button).
class LobbyInvitesShimmer extends StatelessWidget {
  final int itemCount;
  final bool shrinkWrap;

  const LobbyInvitesShimmer({
    super.key,
    this.itemCount = 4,
    this.shrinkWrap = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.md),
      shrinkWrap: shrinkWrap,
      physics: shrinkWrap
          ? const NeverScrollableScrollPhysics()
          : const AlwaysScrollableScrollPhysics(),
      itemCount: itemCount,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (_, _) => const _InviteTileSkeleton(),
    );
  }
}

class _InviteTileSkeleton extends StatelessWidget {
  const _InviteTileSkeleton();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgBase = isDark ? AppColors.surfaceElevatedDark : AppColors.surface;

    return AppShimmer.shimmer(
      context: context,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: bgBase,
          borderRadius: AppRadius.radiusLgAll,
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.border,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            // Avatar tròn
            AppShimmer.circle(context: context, size: 48),
            const SizedBox(width: AppSpacing.md),
            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Container(
                    width: 160,
                    height: 11,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Container(
                    width: 100,
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
            // Action button
            Container(
              width: 76,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: AppRadius.radiusSmAll,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shimmer skeleton cho LobbyRatingPage — hiển thị khi đang load
/// rating data (cần rating criteria + Karma submission panel).
class LobbyRatingShimmer extends StatelessWidget {
  const LobbyRatingShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgBase = isDark ? AppColors.surfaceElevatedDark : AppColors.surface;

    return Scaffold(
      appBar: AppBar(title: const Text('Đánh giá Karma')),
      body: AppShimmer.shimmer(
        context: context,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            // Header card
            Container(
              width: double.infinity,
              height: 100,
              decoration: BoxDecoration(
                color: bgBase,
                borderRadius: AppRadius.radiusLgAll,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            // Rating criteria items
            ...List.generate(
              4,
              (_) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Container(
                  width: double.infinity,
                  height: 72,
                  decoration: BoxDecoration(
                    color: bgBase,
                    borderRadius: AppRadius.radiusMdAll,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            // Submit button
            Container(
              width: double.infinity,
              height: 48,
              decoration: BoxDecoration(
                color: bgBase,
                borderRadius: AppRadius.radiusMdAll,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shimmer skeleton cho MatchResultPage khi loading.
class MatchResultShimmer extends StatelessWidget {
  const MatchResultShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgBase = isDark ? AppColors.surfaceElevatedDark : AppColors.surface;

    return Scaffold(
      appBar: AppBar(title: const Text('Kết quả')),
      body: AppShimmer.shimmer(
        context: context,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            Container(
              width: double.infinity,
              height: 180,
              decoration: BoxDecoration(
                color: bgBase,
                borderRadius: AppRadius.radiusLgAll,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            ...List.generate(
              3,
              (_) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Container(
                  width: double.infinity,
                  height: 64,
                  decoration: BoxDecoration(
                    color: bgBase,
                    borderRadius: AppRadius.radiusMdAll,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Container(
              width: double.infinity,
              height: 48,
              decoration: BoxDecoration(
                color: bgBase,
                borderRadius: AppRadius.radiusMdAll,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Generic shimmer placeholder — bất kỳ page nào đang loading chỉ cần
/// show một skeleton tổng quát (thay cho spinner).
class GenericPageShimmer extends StatelessWidget {
  final int itemCount;
  final double tileHeight;
  final String? appBarTitle;

  const GenericPageShimmer({
    super.key,
    this.itemCount = 5,
    this.tileHeight = 80,
    this.appBarTitle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgBase = isDark ? AppColors.surfaceElevatedDark : AppColors.surface;

    return Scaffold(
      appBar: appBarTitle == null ? null : AppBar(title: Text(appBarTitle!)),
      body: AppShimmer.shimmer(
        context: context,
        child: ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: itemCount,
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
          itemBuilder: (_, _) => Container(
            width: double.infinity,
            height: tileHeight,
            decoration: BoxDecoration(
              color: bgBase,
              borderRadius: AppRadius.radiusMdAll,
            ),
          ),
        ),
      ),
    );
  }
}
