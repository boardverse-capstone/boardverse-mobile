import 'dart:async';
import 'package:flutter/material.dart';

class DepositCountdownTimer extends StatefulWidget {
  final DateTime deadline;
  final VoidCallback? onExpired;

  const DepositCountdownTimer({
    super.key,
    required this.deadline,
    this.onExpired,
  });

  @override
  State<DepositCountdownTimer> createState() => _DepositCountdownTimerState();
}

class _DepositCountdownTimerState extends State<DepositCountdownTimer> {
  late Timer _timer;
  Duration _remainingTime = Duration.zero;

  @override
  void initState() {
    super.initState();
    _calculateRemainingTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _calculateRemainingTime();
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _calculateRemainingTime() {
    final remaining = widget.deadline.difference(DateTime.now());
    setState(() {
      _remainingTime = remaining.isNegative ? Duration.zero : remaining;
    });

    if (_remainingTime == Duration.zero && widget.onExpired != null) {
      widget.onExpired!();
      _timer.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final minutes = _remainingTime.inMinutes;
    final seconds = _remainingTime.inSeconds % 60;
    final isUrgent = _remainingTime.inMinutes < 2;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isUrgent ? Colors.red.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isUrgent ? Colors.red.shade300 : Colors.orange.shade300,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.timer,
            color: isUrgent ? Colors.red.shade700 : Colors.orange.shade700,
            size: 32,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Thời gian còn lại để đóng cọc',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isUrgent
                        ? Colors.red.shade700
                        : Colors.orange.shade800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isUrgent ? Colors.red.shade700 : Colors.orange.shade800,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
          if (isUrgent)
            Icon(
              Icons.warning_amber_rounded,
              color: Colors.red.shade700,
              size: 32,
            ),
        ],
      ),
    );
  }
}
