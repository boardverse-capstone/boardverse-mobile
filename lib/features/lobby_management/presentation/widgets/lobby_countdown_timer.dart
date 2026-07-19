import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';

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
    final colors = theme.colorScheme;
    final minutes = _remainingTime.inMinutes;
    final seconds = _remainingTime.inSeconds % 60;
    final isUrgent = _remainingTime.inMinutes < 5;
    final normalColor = theme.brightness == Brightness.dark
        ? AppColorsDark.info
        : AppColors.info;
    final timerColor = isUrgent ? colors.error : normalColor;
    final formatted =
        '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    return Semantics(
      liveRegion: isUrgent,
      label: 'Còn $minutes phút $seconds giây',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: timerColor.withValues(alpha: 0.11),
          borderRadius: AppRadius.radiusFullAll,
          border: Border.all(color: timerColor.withValues(alpha: 0.34)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(AppIcons.clock, size: AppIcons.md, color: timerColor),
            const SizedBox(width: AppSpacing.xs),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  formatted,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: timerColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  isUrgent ? 'Sắp hết hạn' : 'Thời gian còn lại',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: timerColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
