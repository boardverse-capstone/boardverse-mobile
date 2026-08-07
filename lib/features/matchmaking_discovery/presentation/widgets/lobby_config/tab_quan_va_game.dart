import 'package:flutter/material.dart';

import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/widgets/safe_network_image.dart';
import '../../../domain/entities/board_game_detail_entity.dart';
import '../../../domain/entities/board_game_entity.dart';
import '../../../domain/entities/cafe_entity.dart';
import 'bottom_button.dart';

/// Tab 1 của LobbyConfigPage — hiển thị thông tin quán + game đã chọn.
class LobbyConfigTabQuanVaGame extends StatelessWidget {
  final String cafeName;
  final CafeEntity? cafeEntity;
  final String gameName;
  final BoardGameEntity? gameEntity;
  final BoardGameDetailEntity? gameDetail;
  final VoidCallback onChangeCafe;
  final VoidCallback onNext;

  const LobbyConfigTabQuanVaGame({
    super.key,
    required this.cafeName,
    this.cafeEntity,
    required this.gameName,
    this.gameEntity,
    this.gameDetail,
    required this.onChangeCafe,
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
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  'Kiểm tra lại quán và game trước khi tiếp tục',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // ── Game Card ─────────────────────────────────────────────
                _GameInfoCard(
                  gameEntity: gameEntity,
                  gameDetail: gameDetail,
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
// Game Info Card — ảnh lớn + rating + meta chips
// ══════════════════════════════════════════════════════════════════════════

class _GameInfoCard extends StatelessWidget {
  final BoardGameEntity? gameEntity;
  final BoardGameDetailEntity? gameDetail;

  const _GameInfoCard({this.gameEntity, this.gameDetail});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasDetail = gameDetail != null;
    final imageUrl = gameDetail?.thumbnailUrl ?? gameEntity?.imageUrl ?? '';
    final rating = gameEntity?.rating ?? 0.0;
    final category = gameDetail?.categories.isNotEmpty == true
        ? gameDetail!.categories.first.name
        : (gameEntity?.category.isNotEmpty == true ? gameEntity!.category : null);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: AppRadius.radiusLgAll,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Image banner ────────────────────────────────────────────
          AspectRatio(
            aspectRatio: 16 / 7,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Image
                if (imageUrl.isNotEmpty)
                  SafeNetworkImage(
                    url: imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (ctx, _, _) => _GameImagePlaceholder(theme: theme),
                  )
                else
                  _GameImagePlaceholder(theme: theme),

                // Gradient overlay
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.7),
                        ],
                      ),
                    ),
                  ),
                ),

                // Game name overlay
                Positioned(
                  bottom: AppSpacing.md,
                  left: AppSpacing.md,
                  right: AppSpacing.md,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (category != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(alpha: 0.9),
                            borderRadius: AppRadius.radiusFullAll,
                          ),
                          child: Text(
                            category,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      if (category != null) const SizedBox(height: AppSpacing.xxs),
                      Text(
                        gameDetail?.name ?? 'Board Game',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              color: Colors.black.withValues(alpha: 0.5),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // HOT badge (if rating high)
                if (rating >= 4.0)
                  Positioned(
                    top: AppSpacing.sm,
                    right: AppSpacing.sm,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xxs,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: AppRadius.radiusFullAll,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.local_fire_department,
                              size: 14, color: Colors.white),
                          const SizedBox(width: 2),
                          Text(
                            'HOT',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // ── Meta row ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                // Rating
                _MetaChip(
                  icon: Icons.star,
                  iconColor: Colors.amber,
                  label: rating > 0 ? rating.toStringAsFixed(1) : '—',
                  labelColor: Colors.amber,
                ),
                const SizedBox(width: AppSpacing.sm),

                // Players
                _MetaChip(
                  icon: Icons.people,
                  iconColor: theme.colorScheme.primary,
                  label: hasDetail
                      ? '${gameDetail!.minPlayers}-${gameDetail!.maxPlayers} người'
                      : '2-6 người',
                  labelColor: theme.colorScheme.primary,
                ),
                const SizedBox(width: AppSpacing.sm),

                // Play time
                _MetaChip(
                  icon: Icons.schedule,
                  iconColor: theme.colorScheme.secondary,
                  label: hasDetail
                      ? '${gameDetail!.playTime} phút'
                      : '60 phút',
                  labelColor: theme.colorScheme.secondary,
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
  final ThemeData theme;
  const _GameImagePlaceholder({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: theme.colorScheme.primaryContainer,
      child: Center(
        child: Icon(
          Icons.extension,
          size: 64,
          color: theme.colorScheme.primary.withValues(alpha: 0.4),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// Cafe Info Card — ảnh + address + rating + distance + deposit
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
    final imageUrl = cafeEntity?.imageUrl;
    final address = cafeEntity?.address ?? '';
    final rating = cafeEntity?.rating ?? 0.0;
    final distanceMeters = cafeEntity?.distanceMeters ?? 0.0;
    final depositAmount = cafeEntity?.depositAmount ?? 0.0;
    final availableTables = cafeEntity?.availableTables ?? 0;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: AppRadius.radiusLgAll,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Image + Name row ────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                // Cafe image
                ClipRRect(
                  borderRadius: AppRadius.radiusSmAll,
                  child: SizedBox(
                    width: 72,
                    height: 72,
                    child: imageUrl != null && imageUrl.isNotEmpty
                        ? SafeNetworkImage(
                            url: imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (ctx, _, _) =>
                                _CafeImagePlaceholder(theme: theme),
                          )
                        : _CafeImagePlaceholder(theme: theme),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),

                // Name + Address
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              cafeName,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: onChangeCafe,
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm,
                              ),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text('Đổi quán'),
                          ),
                        ],
                      ),
                      if (address.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 14,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                address,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
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
          const Divider(height: 1, indent: AppSpacing.md, endIndent: AppSpacing.md),

          // ── Meta row ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                // Rating
                _MetaChip(
                  icon: Icons.star,
                  iconColor: Colors.amber,
                  label: rating > 0 ? rating.toStringAsFixed(1) : '—',
                  labelColor: Colors.amber,
                ),
                const SizedBox(width: AppSpacing.sm),

                // Distance
                _MetaChip(
                  icon: Icons.near_me,
                  iconColor: theme.colorScheme.tertiary,
                  label: _formatDistance(distanceMeters),
                  labelColor: theme.colorScheme.tertiary,
                ),

                if (availableTables > 0) ...[
                  const SizedBox(width: AppSpacing.sm),
                  _MetaChip(
                    icon: Icons.table_bar,
                    iconColor: theme.colorScheme.primary,
                    label: '$availableTables bàn',
                    labelColor: theme.colorScheme.primary,
                  ),
                ],

                const Spacer(),

                // Deposit badge
                if (depositAmount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xxs,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: AppRadius.radiusFullAll,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.savings_outlined,
                          size: 14,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatDeposit(depositAmount),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
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

  String _formatDeposit(double amount) {
    if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}k cọc';
    }
    return '${amount.toStringAsFixed(0)} cọc';
  }
}

class _CafeImagePlaceholder extends StatelessWidget {
  final ThemeData theme;
  const _CafeImagePlaceholder({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: theme.colorScheme.secondaryContainer,
      child: Center(
        child: Icon(
          Icons.local_cafe,
          size: 32,
          color: theme.colorScheme.secondary.withValues(alpha: 0.4),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// Shared Meta Chip
// ══════════════════════════════════════════════════════════════════════════

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final Color labelColor;

  const _MetaChip({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.labelColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.1),
        borderRadius: AppRadius.radiusFullAll,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: iconColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: labelColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
