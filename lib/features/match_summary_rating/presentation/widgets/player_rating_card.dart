import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';
import '../../domain/entities/rating_entity.dart';
import '../cubit/rating_state.dart';

class PlayerRatingCard extends StatelessWidget {
  final RatingPlayer player;
  final List<KarmaTag> availableTags;
  final Function(String playerId, String tagId) onTagToggle;

  const PlayerRatingCard({
    super.key,
    required this.player,
    required this.availableTags,
    required this.onTagToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final hasAvatar = player.avatarUrl.trim().isNotEmpty;
    final initial = player.name.trim().isEmpty
        ? '?'
        : player.name.trim().characters.first.toUpperCase();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: AppRadius.cardRadius,
        border: Border.all(color: colors.outlineVariant),
        boxShadow: AppElevation.shadowXs,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: AppSpacing.xl,
                backgroundColor: colors.secondaryContainer,
                foregroundColor: colors.onSecondaryContainer,
                backgroundImage: hasAvatar
                    ? NetworkImage(player.avatarUrl)
                    : null,
                onBackgroundImageError: hasAvatar ? (_, _) {} : null,
                child: hasAvatar
                    ? null
                    : Text(
                        initial,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: colors.onSecondaryContainer,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      player.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      'Chọn nhiều thẻ để mô tả trải nghiệm của bạn.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: availableTags.map((tag) {
              final isSelected = player.selectedTagIds.contains(tag.id);
              return _KarmaTagChip(
                tag: tag,
                isSelected: isSelected,
                onTap: () => onTagToggle(player.id, tag.id),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _KarmaTagChip extends StatelessWidget {
  final KarmaTag tag;
  final bool isSelected;
  final VoidCallback onTap;

  const _KarmaTagChip({
    required this.tag,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final accent = tag.isPositive
        ? theme.brightness == Brightness.dark
              ? AppColorsDark.success
              : AppColors.success
        : theme.brightness == Brightness.dark
        ? AppColorsDark.error
        : AppColors.error;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: isSelected
            ? accent.withValues(alpha: 0.16)
            : colors.surfaceContainerHighest,
        borderRadius: AppRadius.chipRadius,
        border: Border.all(
          color: isSelected ? accent : colors.outlineVariant,
          width: isSelected ? 1.5 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: AppRadius.chipRadius,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _resolveIcon(tag.icon),
                  size: AppIcons.sm,
                  color: isSelected ? accent : colors.onSurfaceVariant,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  tag.name,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: isSelected ? accent : colors.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (isSelected) ...[
                  const SizedBox(width: AppSpacing.xs),
                  Icon(AppIcons.check, size: AppIcons.sm, color: accent),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _resolveIcon(String iconName) {
    switch (iconName) {
      case 'check_circle':
        return AppIcons.available;
      case 'thumb_up':
        return Icons.thumb_up_outlined;
      case 'emoji_emotions':
        return Icons.emoji_emotions_outlined;
      case 'stars':
        return Icons.stars_outlined;
      case 'mood_bad':
        return Icons.mood_bad_outlined;
      case 'event_busy':
        return AppIcons.busy;
      case 'schedule':
        return AppIcons.schedule;
      case 'gavel':
        return Icons.gavel_outlined;
      default:
        return Icons.label_outline;
    }
  }
}
