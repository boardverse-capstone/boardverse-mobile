import 'package:flutter/material.dart';

import 'package:boardverse_mobile/core/theme/theme.dart';

/// Shimmer skeleton cho LobbyPage — thay thế `LobbyLoadingScaffold`
/// (spinner đơn giản) bằng skeleton mô phỏng layout thật để có cảm giác
/// load mượt và tránh "flash" khi data về.
///
/// Layout mô phỏng:
/// 1. Hero header (gradient + game name + cafe name + status badge)
/// 2. Big info card (game time + players count)
/// 3. Player grid (4-6 cells)
/// 4. Chat section placeholder
/// 5. Bottom bar placeholder
///
/// Hiển thị khi `LobbyCubit` đang emit `LobbyLoading`. Khi data về → cross
/// fade vào layout thật.
class LobbyPageShimmer extends StatelessWidget {
  /// Số slot player muốn hiển thị trong skeleton.
  final int playerSlots;

  /// Trong skeleton có chat section hay không (false = bỏ qua).
  final bool showChatSection;

  const LobbyPageShimmer({
    super.key,
    this.playerSlots = 4,
    this.showChatSection = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Phòng chờ'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  // ── Hero header skeleton ─────────────────────────────
                  _HeroHeaderSkeleton(),
                  const SizedBox(height: AppSpacing.md),

                  // ── Info card skeleton ───────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                    ),
                    child: _InfoCardSkeleton(),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // ── Player grid skeleton ─────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                    ),
                    child: _SectionTitleSkeleton(width: 160),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                    ),
                    child: _PlayerGridSkeleton(slots: playerSlots),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // ── Chat section skeleton (optional) ─────────────────
                  if (showChatSection) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                      ),
                      child: _SectionTitleSkeleton(width: 120),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                      ),
                      child: _ChatSkeleton(),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      // ── Bottom bar skeleton ─────────────────────────────
      bottomNavigationBar: _BottomBarSkeleton(),
      backgroundColor: colors.surface,
    );
  }
}

/// ─── Hero header ─────────────────────────────────────────────────────────
class _HeroHeaderSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgBase = isDark ? AppColors.surfaceElevatedDark : AppColors.surface;

    return AppShimmer.shimmer(
      context: context,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: bgBase,
          border: Border(
            bottom: BorderSide(
              color: isDark ? AppColors.borderDark : AppColors.border,
              width: 2,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status badge
            Container(
              width: 128,
              height: 28,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: AppRadius.radiusSmAll,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            // Game name
            Container(
              width: double.infinity,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            // Game name line 2 (shorter)
            Container(
              width: 220,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            // Cafe name + address
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
              width: 180,
              height: 14,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ─── Info card (time + players) ──────────────────────────────────────────
class _InfoCardSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgBase = isDark ? AppColors.surfaceElevatedDark : AppColors.surface;

    return AppShimmer.shimmer(
      context: context,
      child: Container(
        width: double.infinity,
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
            // Time box
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 64,
                    height: 11,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Container(
                    width: 88,
                    height: 18,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
            // Divider
            Container(
              width: 2,
              height: 36,
              color: Colors.white,
            ),
            const SizedBox(width: AppSpacing.md),
            // Players box
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 64,
                    height: 11,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Container(
                    width: 56,
                    height: 18,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ─── Section title (e.g. "Thành viên") ──────────────────────────────────
class _SectionTitleSkeleton extends StatelessWidget {
  final double width;
  const _SectionTitleSkeleton({required this.width});

  @override
  Widget build(BuildContext context) {
    return AppShimmer.shimmer(
      context: context,
      child: Container(
        width: width,
        height: 16,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}

/// ─── Player grid (4 cells matching LobbyPlayerGrid 2-col tablet / 3-col mobile) ──
class _PlayerGridSkeleton extends StatelessWidget {
  final int slots;
  const _PlayerGridSkeleton({required this.slots});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Match LobbyPlayerGrid: 2 cols on tablet, 3 cols on mobile.
        // Phase 3 2026-08-10: match real `LobbyPlayerGrid` — 2 cards/hàng
        // cố định (cả mobile + tablet). Trước đây dùng 3/4 cols gây lệch
        // với layout thật → flash khi data về.
        const crossAxisCount = 2;
        final tileSize =
            (constraints.maxWidth - (crossAxisCount - 1) * AppSpacing.md) /
                crossAxisCount;

        return Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: List.generate(slots, (i) {
            return SizedBox(
              width: tileSize,
              height: tileSize * 1.4, // gần tỉ lệ 0.72 ngược
              child: const _PlayerTileSkeleton(),
            );
          }),
        );
      },
    );
  }
}

class _PlayerTileSkeleton extends StatelessWidget {
  const _PlayerTileSkeleton();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgBase = isDark ? AppColors.surfaceElevatedDark : AppColors.surface;

    return AppShimmer.shimmer(
      context: context,
      child: Container(
        decoration: BoxDecoration(
          color: bgBase,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.border,
            width: 2,
          ),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: AppSpacing.sm,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Avatar circle
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            // Name
            Container(
              width: double.infinity,
              height: 12,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            // Status chip
            Container(
              width: 60,
              height: 16,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ─── Chat section skeleton ───────────────────────────────────────────────
class _ChatSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgBase = isDark ? AppColors.surfaceElevatedDark : AppColors.surface;

    return AppShimmer.shimmer(
      context: context,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: bgBase,
          borderRadius: AppRadius.radiusLgAll,
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.border,
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 3 message bubbles
            _BubbleSkeleton(width: 220),
            const SizedBox(height: AppSpacing.sm),
            _BubbleSkeleton(width: 160, alignEnd: true),
            const SizedBox(height: AppSpacing.sm),
            _BubbleSkeleton(width: 240),
          ],
        ),
      ),
    );
  }
}

class _BubbleSkeleton extends StatelessWidget {
  final double width;
  final bool alignEnd;
  const _BubbleSkeleton({required this.width, this.alignEnd = false});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignEnd ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        width: width,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}

/// ─── Bottom bar skeleton ─────────────────────────────────────────────────
class _BottomBarSkeleton extends StatelessWidget {
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
          border: Border(
            top: BorderSide(
              color: isDark ? AppColors.borderDark : AppColors.border,
              width: 2,
            ),
          ),
        ),
        child: Row(
          children: [
            // Two action buttons
            Expanded(
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: AppRadius.radiusMdAll,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: AppRadius.radiusMdAll,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
