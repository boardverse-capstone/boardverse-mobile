import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/neo_brutalism_theme.dart';
import '../../../../../core/widgets/safe_network_image.dart';
import '../../../domain/entities/board_game_detail_entity.dart';
import '../../../domain/entities/board_game_entity.dart';
import '../../../domain/entities/cafe_entity.dart';
import 'bottom_button.dart';

/// Tab 1 của LobbyConfigPage — hiển thị thông tin quán + game đã chọn.
///
/// Style: Neo-brutalism theo design system v4.0 (`.agents/docs/design_system.md`).
/// - Card: border đậm 3px, hard offset shadow (5, 5), radius 16-20px.
/// - Chips: border 2px, hard shadow (2, 2), background subtle.
/// - Buttons: border đậm + hard shadow + nền đặc (primary) hoặc trắng (outline).
///
/// Layout thông tin CRITICAL (tên game, tên quán) LUÔN nằm ngoài ảnh,
/// trong card body với padding rõ ràng để đảm bảo đọc được trong mọi
/// điều kiện (ảnh load fail, dark mode, screen nhỏ). Ảnh chỉ đóng vai
/// trò trang trí + HOT badge overlay.
class LobbyConfigTabQuanVaGame extends StatelessWidget {
  final String cafeName;
  final CafeEntity? cafeEntity;
  final String gameName;
  final BoardGameEntity? gameEntity;
  final BoardGameDetailEntity? gameDetail;
  final VoidCallback onChangeCafe;

  /// Callback khi player ấn "Đổi game". Mở bottom sheet picker.
  final VoidCallback? onChangeGame;

  final VoidCallback onNext;

  const LobbyConfigTabQuanVaGame({
    super.key,
    required this.cafeName,
    this.cafeEntity,
    required this.gameName,
    this.gameEntity,
    this.gameDetail,
    required this.onChangeCafe,
    this.onChangeGame,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: AppSpacing.paddingAllMd,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ────────────────────────────────────────────────
                Text(
                  'Xác nhận thông tin',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  'Kiểm tra lại quán và game trước khi tiếp tục',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: NeoBrutalismTheme.textSecondaryColor(context),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // ── Game Card ─────────────────────────────────────────────
                _GameInfoCard(
                  gameEntity: gameEntity,
                  gameDetail: gameDetail,
                  onChangeGame: onChangeGame,
                ),
                const SizedBox(height: AppSpacing.md),

                // ── Cafe Card ────────────────────────────────────────────
                _CafeInfoCard(
                  cafeEntity: cafeEntity,
                  cafeName: cafeName,
                  onChangeCafe: onChangeCafe,
                ),
              ],
            ),
          ),
        ),

        // Bottom button
        LobbyConfigBottomButton(
          label: 'Tiếp tục',
          onPressed: onNext,
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// GAME INFO CARD — ảnh trang trí + body chứa tên/category/chips
// ══════════════════════════════════════════════════════════════════════════

class _GameInfoCard extends StatelessWidget {
  final BoardGameEntity? gameEntity;
  final BoardGameDetailEntity? gameDetail;
  final VoidCallback? onChangeGame;

  const _GameInfoCard({
    this.gameEntity,
    this.gameDetail,
    this.onChangeGame,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final hasDetail = gameDetail != null;
    final imageUrl = gameDetail?.thumbnailUrl ?? gameEntity?.imageUrl ?? '';
    final rating = gameEntity?.rating ?? 0.0;
    final category = gameDetail?.categories.isNotEmpty == true
        ? gameDetail!.categories.first.name
        : (gameEntity?.category.isNotEmpty == true
            ? gameEntity!.category
            : null);

    return Container(
      decoration: NeoBrutalismTheme.autoBox(
        context,
        backgroundColor:
            isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: 20,
        bold: true,
        shadowColor: AppColors.primary.withValues(alpha: 0.2),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Image banner — chỉ làm trang trí + HOT badge overlay ────
          Stack(
            children: [
              AspectRatio(
                aspectRatio: 16 / 7,
                child: imageUrl.isNotEmpty
                    ? SafeNetworkImage(
                        url: imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (ctx, _, _) =>
                            _GameImagePlaceholder(),
                      )
                    : _GameImagePlaceholder(),
              ),

              // HOT badge — chỉ overlay lên ảnh (top-left), không
              // đè lên text quan trọng
              if (rating >= 4.5)
                Positioned(
                  top: AppSpacing.sm,
                  left: AppSpacing.sm,
                  child: IgnorePointer(
                    child: _StatusPill(
                      icon: Icons.local_fire_department,
                      label: 'HOT',
                      background: AppColors.warning,
                      foreground: AppColors.black,
                    ),
                  ),
                ),
            ],
          ),

          // ── Game name + category + Đổi game button (in body) ─────────
          // Thông tin quan trọng ở trên nền card, không overlay ảnh,
          // đảm bảo đọc được trong mọi trường hợp.
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category chip
                if (category != null) ...[
                  _StatusPill(
                    icon: Icons.bookmark_outline,
                    label: category,
                    background:
                        AppColors.primary.withValues(alpha: 0.12),
                    foreground: AppColors.primary,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],

                // Name + Đổi game row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        gameDetail?.name ?? gameEntity?.name ?? 'Board Game',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    if (onChangeGame != null)
                      _ChangeButtonNeo(
                        label: 'Đổi game',
                        onPressed: onChangeGame!,
                      ),
                  ],
                ),
              ],
            ),
          ),

          // ── Divider ────────────────────────────────────────────────
          Divider(
            height: 1,
            thickness: 1.5,
            color: isDark ? AppColors.borderDark : AppColors.border,
            indent: AppSpacing.md,
            endIndent: AppSpacing.md,
          ),

          // ── Meta chips row ───────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                // Rating — ẩn khi chưa có đánh giá
                if (rating > 0)
                  _MetaChipNeo(
                    icon: Icons.star_rounded,
                    label: rating.toStringAsFixed(1),
                    accent: AppColors.warning,
                  ),

                // Players
                _MetaChipNeo(
                  icon: Icons.group_rounded,
                  label: hasDetail ? gameDetail!.playerRangeDisplay : '2-6 người',
                  accent: AppColors.primary,
                ),

                // Play time
                _MetaChipNeo(
                  icon: Icons.schedule_rounded,
                  label: hasDetail
                      ? '${gameDetail!.playTime} phút'
                      : '60 phút',
                  accent: AppColors.secondary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GameImagePlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      color: isDark
          ? AppColors.surfaceElevatedDark
          : AppColors.primary.withValues(alpha: 0.08),
      child: Center(
        child: Icon(
          Icons.casino_outlined,
          size: 56,
          color: isDark
              ? AppColors.textPrimaryDark.withValues(alpha: 0.4)
              : AppColors.primary.withValues(alpha: 0.4),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// CAFE INFO CARD — thumbnail + tên + địa chỉ + meta chips
// ══════════════════════════════════════════════════════════════════════════

class _CafeInfoCard extends StatelessWidget {
  final CafeEntity? cafeEntity;
  final String cafeName;
  final VoidCallback onChangeCafe;

  const _CafeInfoCard({
    required this.cafeEntity,
    required this.cafeName,
    required this.onChangeCafe,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final imageUrl = cafeEntity?.imageUrl;
    final address = cafeEntity?.address ?? '';
    final rating = cafeEntity?.rating ?? 0.0;
    final distanceMeters = cafeEntity?.distanceMeters ?? 0.0;
    final availableTables = cafeEntity?.availableTables ?? 0;

    return Container(
      decoration: NeoBrutalismTheme.autoBox(
        context,
        backgroundColor:
            isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: 20,
        bold: true,
        shadowColor: AppColors.secondary.withValues(alpha: 0.2),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Image + Name row ────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cafe thumbnail — neo border + hard shadow
                Container(
                  decoration: NeoBrutalismTheme.brutalBox(
                    backgroundColor: theme.colorScheme.secondaryContainer,
                    borderColor:
                        isDark ? AppColors.borderDark : AppColors.border,
                    bold: false,
                    borderRadius: 12,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: SizedBox(
                    width: 72,
                    height: 72,
                    child: imageUrl != null && imageUrl.isNotEmpty
                        ? SafeNetworkImage(
                            url: imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (ctx, _, _) =>
                                _CafeImagePlaceholder(),
                          )
                        : _CafeImagePlaceholder(),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),

                // Name + Address + Đổi quán
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name + Đổi quán row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              cafeName,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: isDark
                                    ? AppColors.textPrimaryDark
                                    : AppColors.textPrimary,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          _ChangeButtonNeo(
                            label: 'Đổi quán',
                            onPressed: onChangeCafe,
                          ),
                        ],
                      ),
                      if (address.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.location_on_rounded,
                              size: 16,
                              color:
                                  NeoBrutalismTheme.textSecondaryColor(context),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                address,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: NeoBrutalismTheme.textSecondaryColor(
                                      context),
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Divider ────────────────────────────────────────────────
          Divider(
            height: 1,
            thickness: 1.5,
            color: isDark ? AppColors.borderDark : AppColors.border,
            indent: AppSpacing.md,
            endIndent: AppSpacing.md,
          ),

          // ── Meta chips row ───────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                // Rating — ẩn khi chưa có đánh giá
                if (rating > 0)
                  _MetaChipNeo(
                    icon: Icons.star_rounded,
                    label: rating.toStringAsFixed(1),
                    accent: AppColors.warning,
                  ),

                // Distance
                _MetaChipNeo(
                  icon: Icons.near_me_rounded,
                  label: _formatDistance(distanceMeters),
                  accent: AppColors.accent,
                ),

                if (availableTables > 0)
                  _MetaChipNeo(
                    icon: Icons.table_bar_rounded,
                    label: '$availableTables bàn trống',
                    accent: AppColors.success,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.toInt()}m';
    }
    return '${(meters / 1000).toStringAsFixed(1)}km';
  }
}

class _CafeImagePlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      color: isDark
          ? AppColors.surfaceElevatedDark
          : AppColors.secondary.withValues(alpha: 0.12),
      child: Center(
        child: Icon(
          Icons.local_cafe_outlined,
          size: 32,
          color: AppColors.secondary.withValues(alpha: 0.6),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// SHARED WIDGETS — theo design system
// ══════════════════════════════════════════════════════════════════════════

/// _ChangeButtonNeo — Button inline theo style neo-brutalism:
/// nền trắng (outline), viền đen 2px, hard offset shadow 3,3, padding compact.
///
/// Dùng cho "Đổi game" / "Đổi quán" — secondary action không phải CTA chính
/// nhưng vẫn phải rõ ràng và tap-able dễ dàng.
class _ChangeButtonNeo extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _ChangeButtonNeo({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: isDark ? AppColors.surfaceDark : AppColors.white,
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: isDark ? AppColors.borderDark : AppColors.border,
          width: NeoBrutalismTheme.borderWidthBold,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 0,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: NeoBrutalismTheme.lightShadow(
              shadowColor: AppColors.primary.withValues(alpha: 0.35),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.swap_horiz_rounded,
                size: 16,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimary,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// _StatusPill — Pill nhỏ cho badge (HOT, category). Border 2px, hard
/// shadow nhẹ, text bold đậm. Không dùng cho action — chỉ hiển thị thông tin.
class _StatusPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color background;
  final Color foreground;

  const _StatusPill({
    required this.icon,
    required this.label,
    required this.background,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.border,
          width: NeoBrutalismTheme.borderWidth,
        ),
        boxShadow: NeoBrutalismTheme.lightShadow(
          shadowColor: background.computeLuminance() > 0.5
              ? AppColors.black.withValues(alpha: 0.15)
              : background.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: foreground),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w900,
              fontSize: 10,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

/// _MetaChipNeo — Meta info chip với border 2px, hard shadow (2, 2),
/// background subtle (12% accent color), text đen. Theo pattern chip
/// của TournamentStatusPill và MetaRow.
class _MetaChipNeo extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color accent;

  const _MetaChipNeo({
    required this.icon,
    required this.label,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.border,
          width: NeoBrutalismTheme.borderWidth,
        ),
        boxShadow: NeoBrutalismTheme.lightShadow(
          shadowColor: accent.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: accent),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
