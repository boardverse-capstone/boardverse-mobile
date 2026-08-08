import 'package:flutter/material.dart';

import 'package:boardverse_mobile/core/theme/app_colors.dart';
import 'package:boardverse_mobile/core/theme/app_icons.dart';
import 'package:boardverse_mobile/core/theme/app_spacing.dart';
import '../../domain/entities/rating_entity.dart';
import '../cubit/rating_state.dart';

/// Neo-brutalism player rating card.
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasAvatar = player.avatarUrl.trim().isNotEmpty;
    final initial = player.name.trim().isEmpty
        ? '?'
        : player.name.trim().characters.first.toUpperCase();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.border,
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.4),
            blurRadius: 0,
            offset: const Offset(4, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark ? AppColors.borderDark : AppColors.border,
                    width: 2.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.black.withValues(alpha: 0.4),
                      blurRadius: 0,
                      offset: const Offset(2, 2),
                    ),
                  ],
                ),
                child: hasAvatar
                    ? ClipOval(
                        child: Image.network(
                          player.avatarUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, e, st) => Center(
                            child: Text(
                              initial,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                color: AppColors.white,
                                fontSize: 20,
                              ),
                            ),
                          ),
                        ),
                      )
                    : Center(
                        child: Text(
                          initial,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            color: AppColors.white,
                            fontSize: 20,
                          ),
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
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Chọn nhiều thẻ để mô tả trải nghiệm của bạn.',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondary,
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

/// Neo-brutalism karma tag chip with bold border + hard shadow.
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = tag.isPositive ? AppColors.success : AppColors.error;
    final bg = isSelected
        ? accent
        : (isDark ? AppColors.surfaceElevatedDark : AppColors.surfaceVariant);
    final fg = isSelected
        ? AppColors.white
        : (isDark
            ? AppColors.textPrimaryDark
            : AppColors.textPrimary);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? accent
                  : (isDark ? AppColors.borderDark : AppColors.border),
              width: isSelected ? 2.5 : 2,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.black.withValues(alpha: 0.4),
                      blurRadius: 0,
                      offset: const Offset(2, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _resolveIcon(tag.icon),
                size: 14,
                color: fg,
              ),
              const SizedBox(width: 4),
              Text(
                tag.name,
                style: TextStyle(
                  color: fg,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
              if (isSelected) ...[
                const SizedBox(width: 4),
                const Icon(AppIcons.check, size: 14, color: AppColors.white),
              ],
            ],
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