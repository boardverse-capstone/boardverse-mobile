import 'dart:async';

import 'package:flutter/material.dart';

import 'package:boardverse_mobile/core/theme/app_colors.dart';
import 'package:boardverse_mobile/core/theme/app_spacing.dart';

/// Neo-brutalism play duration timer với bold border + hard shadow.
class PlayDurationTimer extends StatefulWidget {
  final DateTime startTime;
  final bool isRunning;

  const PlayDurationTimer({
    super.key,
    required this.startTime,
    this.isRunning = true,
  });

  @override
  State<PlayDurationTimer> createState() => _PlayDurationTimerState();
}

class _PlayDurationTimerState extends State<PlayDurationTimer> {
  late Timer _timer;
  Duration _duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _duration = DateTime.now().difference(widget.startTime);
    if (widget.isRunning) {
      _startTimer();
    }
  }

  @override
  void didUpdateWidget(PlayDurationTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRunning != oldWidget.isRunning) {
      if (widget.isRunning) {
        _startTimer();
      } else {
        _stopTimer();
      }
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _duration = DateTime.now().difference(widget.startTime);
      });
    });
  }

  void _stopTimer() {
    _timer.cancel();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hours = _duration.inHours;
    final minutes = _duration.inMinutes % 60;
    final seconds = _duration.inSeconds % 60;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.border,
          width: 2.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.4),
            blurRadius: 0,
            offset: const Offset(3, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.border,
                width: 2,
              ),
            ),
            child: const Icon(
              Icons.timer,
              color: AppColors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'THỜI GIAN CHƠI',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 10,
                  letterSpacing: 0.8,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
                  fontFamily: 'monospace',
                  letterSpacing: 1.0,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}