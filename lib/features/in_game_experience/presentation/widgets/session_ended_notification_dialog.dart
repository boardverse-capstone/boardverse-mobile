import 'package:flutter/material.dart';

/// Dialog notification hiển thị khi phiên chơi kết thúc.
///
/// Xuất hiện tự động sau khi nhân viên POS bấm kết thúc phiên.
/// Cho phép user chọn: đánh giá ngay, bình chọn no-show, hoặc để sau.
class SessionEndedNotificationDialog extends StatelessWidget {
  final Duration totalDuration;
  final VoidCallback onRateNow;
  final VoidCallback onVoteNoShow;
  final VoidCallback onLater;

  const SessionEndedNotificationDialog({
    super.key,
    required this.totalDuration,
    required this.onRateNow,
    required this.onVoteNoShow,
    required this.onLater,
  });

  static Future<void> show({
    required BuildContext context,
    required Duration totalDuration,
    required VoidCallback onRateNow,
    required VoidCallback onVoteNoShow,
    required VoidCallback onLater,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => SessionEndedNotificationDialog(
        totalDuration: totalDuration,
        onRateNow: onRateNow,
        onVoteNoShow: onVoteNoShow,
        onLater: onLater,
      ),
    );
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60);
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m ${seconds}s';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      icon: Icon(
        Icons.celebration,
        size: 48,
        color: Colors.amber.shade600,
      ),
      title: const Text('Phiên chơi đã kết thúc!'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Cảm ơn bạn đã tham gia!',
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Thời gian chơi: ${_formatDuration(totalDuration)}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Hãy đánh giá đồng đội và bình chọn người vắng mặt (no-show) để giúp cộng đồng tốt hơn.',
            style: theme.textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            onLater();
          },
          child: const Text('Để sau'),
        ),
        OutlinedButton.icon(
          onPressed: () {
            Navigator.pop(context);
            onVoteNoShow();
          },
          icon: const Icon(Icons.how_to_vote_outlined),
          label: const Text('Bình chọn no-show'),
        ),
        FilledButton.icon(
          onPressed: () {
            Navigator.pop(context);
            onRateNow();
          },
          icon: const Icon(Icons.star_outline),
          label: const Text('Đánh giá ngay'),
        ),
      ],
      actionsAlignment: MainAxisAlignment.spaceBetween,
    );
  }
}
