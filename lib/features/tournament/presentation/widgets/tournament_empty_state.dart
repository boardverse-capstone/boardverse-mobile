import 'package:flutter/material.dart';

class TournamentEmptyState extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;

  const TournamentEmptyState({
    super.key,
    this.title = 'Chưa có giải đấu nào',
    this.message = 'Hãy quay lại sau hoặc chọn bộ lọc khác để xem thêm.',
    this.icon = Icons.emoji_events_outlined,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 80,
            color: theme.colorScheme.outline.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.outline,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
