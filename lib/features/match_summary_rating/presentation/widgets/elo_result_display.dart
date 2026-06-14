import 'package:flutter/material.dart';
import '../../domain/entities/rating_entity.dart';

class EloResultDisplayWidget extends StatelessWidget {
  final EloResult eloResult;
  final VoidCallback? onViewLeaderboard;
  final VoidCallback? onComplete;

  const EloResultDisplayWidget({
    super.key,
    required this.eloResult,
    this.onViewLeaderboard,
    this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPositive = eloResult.eloChange >= 0;
    final changeColor = isPositive ? Colors.green : Colors.red;
    final resultText = switch (eloResult.result) {
      MatchResult.win => 'Thắng',
      MatchResult.lose => 'Thua',
      MatchResult.draw => 'Hòa',
    };
    final resultIcon = switch (eloResult.result) {
      MatchResult.win => Icons.emoji_events,
      MatchResult.lose => Icons.sentiment_dissatisfied,
      MatchResult.draw => Icons.handshake,
    };
    final resultColor = switch (eloResult.result) {
      MatchResult.win => Colors.amber,
      MatchResult.lose => Colors.grey,
      MatchResult.draw => Colors.blue,
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(resultIcon, size: 64, color: resultColor),
            const SizedBox(height: 16),
            Text(
              resultText,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: resultColor,
              ),
            ),
            const SizedBox(height: 24),

            // Elo Change Display
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: changeColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: changeColor.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  Text(
                    'Điểm Elo biến động',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: changeColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                        color: changeColor,
                        size: 32,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${eloResult.eloChange.abs()}',
                        style: theme.textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: changeColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${eloResult.currentElo}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.outline,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        '${eloResult.newElo}',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            if (onViewLeaderboard != null)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onViewLeaderboard,
                  icon: const Icon(Icons.leaderboard),
                  label: const Text('Xem Bảng xếp hạng'),
                ),
              ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onComplete,
                icon: const Icon(Icons.check),
                label: const Text('Hoàn tất'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
