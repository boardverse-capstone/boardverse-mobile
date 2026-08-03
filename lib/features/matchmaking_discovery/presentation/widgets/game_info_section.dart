import 'package:flutter/material.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/board_game_detail_entity.dart';
import '../../domain/entities/board_game_entity.dart';

/// Widget hiển thị thông tin chi tiết của board game.
/// Không chứa category badge (đã có trong GameDetailHeader).
///
/// Sections:
///   1. Description card
///   2. Components card (nếu có)
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Description ────────────────────────────────────────────────
          Text(
            'Mô tả',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            data.description.isEmpty ? 'Đang cập nhật...' : data.description,
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.5,
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // ── Components ─────────────────────────────────────────────────
          if (components.isNotEmpty) ...[
            Text(
              'Linh kiện trong hộp',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '${components.length} món',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            _ComponentsGrid(components: components),
          ],
        ],
      ),
    );
  }
}

/// Grid hiển thị components.
class _ComponentsGrid extends StatelessWidget {
  final List<ComponentData> components;

  const _ComponentsGrid({required this.components});

  @override
  Widget build(BuildContext context) {
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
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: AppRadius.radiusXsAll,
          ),
          child: Row(
            children: [
              Icon(
                Icons.check_box_outlined,
                size: AppSpacing.md,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  components[index].name,
                  style: Theme.of(context).textTheme.bodySmall,
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

// ─── Data classes (public) ────────────────────────────────────────────

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
