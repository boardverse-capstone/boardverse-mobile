import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/neo_brutalism_theme.dart';
import '../../domain/entities/board_game_detail_entity.dart';
import '../../domain/entities/board_game_entity.dart';

/// Neo-brutalism Widget hiển thị thông tin chi tiết của board game.
class GameInfoSection extends StatelessWidget {
  final GameInfoData data;
  final List<ComponentData> components;

  const GameInfoSection._({
    required this.data,
    required this.components,
  });

  factory GameInfoSection.fromDetail(BoardGameDetailEntity game) {
    return GameInfoSection._(
      data: GameInfoData(
        description: game.description,
        minPlayers: game.minPlayers,
        maxPlayers: game.maxPlayers,
        playTimeMinutes: game.playTime,
      ),
      components: game.components
          .map((c) => ComponentData(
                name: c.componentName,
                quantity: c.defaultQuantity,
              ))
          .toList(growable: false),
    );
  }

  factory GameInfoSection.fromEntity(BoardGameEntity game) {
    return GameInfoSection._(
      data: GameInfoData(
        description: game.description,
        minPlayers: game.minPlayers,
        maxPlayers: game.maxPlayers,
        playTimeMinutes: game.estimatedMinutes,
      ),
      components: game.components
          .map((c) => ComponentData(name: c))
          .toList(growable: false),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Description ──────────────────────────────────────────────────
          Container(
            padding: AppSpacing.paddingAllMd,
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.border,
                width: NeoBrutalismTheme.borderWidth,
              ),
              boxShadow: NeoBrutalismTheme.lightShadow(
                shadowColor: AppColors.black.withValues(alpha: 0.06),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.description,
                        color: AppColors.white,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'MÔ TẢ',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  data.description.isEmpty
                      ? 'Đang cập nhật...'
                      : data.description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    height: 1.5,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // ── Components ───────────────────────────────────────────────────
          if (components.isNotEmpty) ...[
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.secondary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.inventory_2,
                    color: AppColors.white,
                    size: 16,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'LINH KIỆN TRONG HỘP',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDark
                          ? AppColors.borderDark
                          : AppColors.border,
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    '${components.length} món',
                    style: const TextStyle(
                      color: AppColors.black,
                      fontWeight: FontWeight.w900,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            _ComponentsList(components: components),
          ],
        ],
      ),
    );
  }
}

/// Danh sách linh kiện dạng card ngang, hiển thị đầy đủ tên + số lượng.
/// Layout dọc thay vì grid để tránh cắt chữ và dễ đọc hơn.
class _ComponentsList extends StatelessWidget {
  final List<ComponentData> components;

  const _ComponentsList({required this.components});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (int i = 0; i < components.length; i++) ...[
          _ComponentCard(component: components[i]),
          if (i < components.length - 1) const SizedBox(height: AppSpacing.xs),
        ],
      ],
    );
  }
}

/// Card ngang hiển thị một linh kiện với icon, tên đầy đủ và badge số lượng.
class _ComponentCard extends StatelessWidget {
  final ComponentData component;

  const _ComponentCard({required this.component});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final hasQuantity = component.quantity != null && component.quantity! > 1;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.border,
          width: NeoBrutalismTheme.borderWidth,
        ),
        boxShadow: NeoBrutalismTheme.lightShadow(
          shadowColor: AppColors.black.withValues(alpha: 0.04),
        ),
      ),
      child: Row(
        children: [
          // Icon marker
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                component.name.isNotEmpty ? component.name[0].toUpperCase() : '?',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),

          // Tên linh kiện
          Expanded(
            child: Text(
              component.name,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Badge số lượng (chỉ hiển thị khi > 1)
          if (hasQuantity) ...[
            const SizedBox(width: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: AppColors.secondary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'x${component.quantity}',
                style: const TextStyle(
                  color: AppColors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class ComponentData {
  final String name;
  final int? quantity;
  const ComponentData({required this.name, this.quantity});
}

class GameInfoData {
  final String description;
  final int minPlayers;
  final int maxPlayers;
  final int playTimeMinutes;

  const GameInfoData({
    required this.description,
    required this.minPlayers,
    required this.maxPlayers,
    required this.playTimeMinutes,
  });
}
