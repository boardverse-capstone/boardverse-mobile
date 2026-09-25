import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/personalized_board_game_entity.dart';

/// Badge hiển thị lịch sử chơi game gần đây.
///
/// Theo backend:
/// - penalty = 0: ẩn badge (chưa chơi gần đây)
/// - penalty = -5: "Đã thử" (yellow)
/// - penalty = -10, -15: "Chơi nhiều" (orange)
/// - penalty = -20: "Chơi rất nhiều" (red)
///
/// Tap badge → hiển thị tooltip.
class PlayHistoryBadge extends StatelessWidget {
  final PlayHistoryLevel level;

  const PlayHistoryBadge({
    super.key,
    required this.level,
  });

  @override
  Widget build(BuildContext context) {
    if (level == PlayHistoryLevel.none) return const SizedBox.shrink();

    final config = _configForLevel(level);

    return GestureDetector(
      onTap: () => _showTooltip(context),
      child: Tooltip(
        message: config.tooltip,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: config.color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: config.color.withValues(alpha: 0.4),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.history_rounded,
                size: 12,
                color: config.color,
              ),
              const SizedBox(width: 4),
              Text(
                config.label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: config.color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTooltip(BuildContext context) {
    final config = _configForLevel(level);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(config.tooltip),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  _BadgeConfig _configForLevel(PlayHistoryLevel level) {
    switch (level) {
      case PlayHistoryLevel.none:
        return const _BadgeConfig(
          label: '',
          color: Colors.transparent,
          tooltip: '',
        );
      case PlayHistoryLevel.light:
        return const _BadgeConfig(
          label: 'Đã thử',
          color: AppColors.warning,
          tooltip: 'Bạn đã chơi game này 1 lần gần đây',
        );
      case PlayHistoryLevel.medium:
        return const _BadgeConfig(
          label: 'Chơi nhiều',
          color: Color(0xFFFF9800),
          tooltip: 'Bạn đã chơi game này 2-3 lần gần đây',
        );
      case PlayHistoryLevel.heavy:
        return const _BadgeConfig(
          label: 'Chơi rất nhiều',
          color: AppColors.error,
          tooltip: 'Bạn đã chơi game này 4+ lần trong 30 ngày qua',
        );
    }
  }
}

class _BadgeConfig {
  final String label;
  final Color color;
  final String tooltip;

  const _BadgeConfig({
    required this.label,
    required this.color,
    required this.tooltip,
  });
}
