import 'dart:async';
import 'package:flutter/material.dart';

class LobbyCountdownTimer extends StatefulWidget {
  final DateTime expiresAt;
  final VoidCallback? onExpired;

  const LobbyCountdownTimer({
    super.key,
    required this.expiresAt,
    this.onExpired,
  });

  @override
  State<LobbyCountdownTimer> createState() => _LobbyCountdownTimerState();
}

class _LobbyCountdownTimerState extends State<LobbyCountdownTimer> {
  late Timer _timer;
  Duration _remainingTime = Duration.zero;

  @override
  void initState() {
    super.initState();
    _remainingTime = _computeRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _calculateRemainingTime();
    });
  }

  Duration _computeRemaining() {
    final remaining = widget.expiresAt.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _calculateRemainingTime() {
    final remaining = _computeRemaining();
    if (!mounted) return;
    setState(() {
      _remainingTime = remaining;
    });

    if (_remainingTime == Duration.zero && widget.onExpired != null) {
      _timer.cancel();
      widget.onExpired!();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final minutes = _remainingTime.inMinutes;
    final seconds = _remainingTime.inSeconds % 60;
    final isUrgent = _remainingTime.inMinutes < 5;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isUrgent
            ? Colors.red.shade50
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
        border: isUrgent
            ? Border.all(color: Colors.red.shade300)
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.timer,
            size: 18,
            color: isUrgent ? Colors.red.shade700 : theme.colorScheme.primary,
          ),
          const SizedBox(width: 6),
          Text(
            '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: isUrgent ? Colors.red.shade700 : null,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'còn lại',
            style: theme.textTheme.bodySmall?.copyWith(
              color: isUrgent
                  ? Colors.red.shade700
                  : theme.colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }
}
