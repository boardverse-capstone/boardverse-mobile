import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Banner đếm ngược dùng cho [PaymentPage] và [BookingSuccessPage].
///
/// Tự quản lý [Timer.periodic] — caller chỉ cần truyền [deadline] và
/// optional [onExpired] callback.
class CountdownBanner extends StatefulWidget {
  final DateTime deadline;
  final VoidCallback? onExpired;
  final String title;

  const CountdownBanner({
    super.key,
    required this.deadline,
    this.onExpired,
    this.title = 'Thời gian giữ chỗ còn lại',
  });

  @override
  State<CountdownBanner> createState() => _CountdownBannerState();
}

class _CountdownBannerState extends State<CountdownBanner> {
  late Timer _timer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _remaining = widget.deadline.difference(DateTime.now());
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final r = widget.deadline.difference(DateTime.now());
      setState(() => _remaining = r.isNegative ? Duration.zero : r);
      if (r.isNegative) {
        _timer.cancel();
        widget.onExpired?.call();
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mm = _remaining.inMinutes.toString().padLeft(2, '0');
    final ss = (_remaining.inSeconds % 60).toString().padLeft(2, '0');
    final isUrgent = _remaining < const Duration(minutes: 2);
    final color = isUrgent ? Colors.red.shade700 : theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.timer_outlined, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$mm:$ss',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                Text(
                  'Đến ${DateFormat('HH:mm').format(widget.deadline)}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}