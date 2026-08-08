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
          .map((c) => ComponentData(name: c.componentName))
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
            _ComponentsGrid(components: components),
          ],
        ],
      ),
    );
  }
}

class _ComponentsGrid extends StatelessWidget {
  final List<ComponentData> components;

  const _ComponentsGrid({required this.components});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 4,
        crossAxisSpacing: AppSpacing.xs,
        mainAxisSpacing: AppSpacing.xs,
      ),
      itemCount: components.length,
      itemBuilder: (context, index) {
        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.border,
              width: NeoBrutalismTheme.borderWidth,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(
                  Icons.check,
                  color: AppColors.white,
                  size: 12,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  components[index].name,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class ComponentData {
  final String name;
  const ComponentData({required this.name});
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
