import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/neo_brutalism_theme.dart';
import '../../../../core/widgets/safe_network_image.dart';
import '../../domain/entities/board_game_entity.dart';

class SimilarGamesCarousel extends StatelessWidget {
  final List<BoardGameEntity> games;
  final Function(BoardGameEntity)? onGameTap;

  const SimilarGamesCarousel({
    super.key,
    required this.games,
    this.onGameTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;

    final cardWidth = screenWidth * 0.38;
    final cardHeight = cardWidth * 4 / 3 + AppSpacing.xxxl;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: AppSpacing.paddingHorizontalMd,
          child: Text(
            'GAME TƯƠNG TỰ',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: cardHeight,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            itemCount: games.length,
            itemBuilder: (context, index) {
              final game = games[index];
              return Container(
                width: cardWidth,
                margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
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
                clipBehavior: Clip.antiAlias,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => onGameTap?.call(game),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: SafeNetworkImage(
                            url: game.imageUrl,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            errorBuilder:
                                (context, error, stackTrace) => Container(
                              color:
                                  theme.colorScheme.surfaceContainerHighest,
                              alignment: Alignment.center,
                              child: Icon(
                                Icons.extension,
                                size: AppSpacing.xxxl,
                                color: theme.colorScheme.outline,
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(AppSpacing.xs),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                game.name,
                                style:
                                    theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: AppSpacing.xxs),
                              Text(
                                '${game.minPlayers}-${game.maxPlayers} người',
                                style:
                                    theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.outline,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
