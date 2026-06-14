import 'package:flutter/material.dart';
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

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundImage: NetworkImage(player.avatarUrl),
                  onBackgroundImageError: (_, _) {},
                  child: player.avatarUrl.isEmpty
                      ? Text(player.name[0].toUpperCase())
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    player.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: availableTags.map((tag) {
                final isSelected = player.selectedTagIds.contains(tag.id);
                return FilterChip(
                  selected: isSelected,
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getIconData(tag.icon),
                        size: 16,
                        color: isSelected
                            ? (tag.isPositive
                                  ? Colors.green.shade700
                                  : Colors.red.shade700)
                            : theme.colorScheme.outline,
                      ),
                      const SizedBox(width: 4),
                      Text(tag.name),
                    ],
                  ),
                  selectedColor: tag.isPositive
                      ? Colors.green.shade100
                      : Colors.red.shade100,
                  onSelected: (_) => onTagToggle(player.id, tag.id),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'check_circle':
        return Icons.check_circle;
      case 'thumb_up':
        return Icons.thumb_up;
      case 'emoji_emotions':
        return Icons.emoji_emotions;
      case 'stars':
        return Icons.stars;
      case 'mood_bad':
        return Icons.mood_bad;
      case 'event_busy':
        return Icons.event_busy;
      case 'schedule':
        return Icons.schedule;
      case 'gavel':
        return Icons.gavel;
      default:
        return Icons.label;
    }
  }
}
