import 'dart:async';

import 'package:flutter/material.dart';

import 'package:boardverse_mobile/core/theme/app_colors.dart';
import 'package:boardverse_mobile/core/theme/app_spacing.dart';

/// Countdown widget tới một thời điểm `scheduledTime`. Neo-brutalism style
/// với bold border + hard shadow.
class ScheduledTimeCountdown extends StatefulWidget {
  final DateTime scheduledTime;
  final String title;
  final String? subtitle;
  final Color accentColor;
  final VoidCallback? onElapsed;
  final bool compact;

  const ScheduledTimeCountdown({
    super.key,
    required this.scheduledTime,
    required this.title,
    this.subtitle,
    this.accentColor = AppColors.success,
    this.onElapsed,
    this.compact = false,
  });

  @override
  State<ScheduledTimeCountdown> createState() => _ScheduledTimeCountdownState();
}

class _ScheduledTimeCountdownState extends State<ScheduledTimeCountdown> {
  late Timer _timer;
  Duration _remaining = Duration.zero;
  bool _isPast = false;
  bool _elapsedCallbackFired = false;

  @override
  void initState() {
    super.initState();
    _update();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _update());
  }

  void _update() {
    final now = DateTime.now();
    final delta = widget.scheduledTime.difference(now);
    if (!mounted) return;
    setState(() {
      _remaining = delta.isNegative ? Duration.zero : delta;
      _isPast = delta.isNegative;
    });
    if (delta.isNegative && !_elapsedCallbackFired) {
      _elapsedCallbackFired = true;
      widget.onElapsed?.call();
    }
  }

  @override
  void didUpdateWidget(covariant ScheduledTimeCountdown old) {
    super.didUpdateWidget(old);
    if (old.scheduledTime != widget.scheduledTime) {
      _elapsedCallbackFired = false;
      _update();
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String get _formatted {
    final h = _remaining.inHours;
    final m = _remaining.inMinutes % 60;
    final s = _remaining.inSeconds % 60;
    if (h > 0) {
      return '${h}h ${m.toString().padLeft(2, '0')}m';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Color get _currentColor {
    if (_isPast) return AppColors.textSecondary;
    if (_remaining.inMinutes <= 30) return AppColors.warning;
    if (_remaining.inHours <= 2) return AppColors.accent;
    return widget.accentColor;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = _currentColor;
    if (widget.compact) {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xxs,
        ),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.border,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.timer_outlined,
                color: _isPast ? AppColors.white : AppColors.black, size: 14),
            const SizedBox(width: AppSpacing.xxs),
            Text(
              _isPast ? 'Đã tới giờ' : _formatted,
              style: TextStyle(
                color: _isPast ? AppColors.white : AppColors.black,
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.border,
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.4),
            blurRadius: 0,
            offset: const Offset(4, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.black.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: Icon(
              _isPast ? Icons.alarm_off_rounded : Icons.alarm_rounded,
              color: _isPast ? AppColors.white : AppColors.black,
              size: 28,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: TextStyle(
                    color: _isPast ? AppColors.white : AppColors.black,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _isPast ? 'Đã tới giờ chơi' : _formatted,
                  style: TextStyle(
                    color: _isPast ? AppColors.white : AppColors.black,
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                    letterSpacing: -1,
                  ),
                ),
                if (widget.subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    widget.subtitle!,
                    style: TextStyle(
                      color: _isPast
                          ? AppColors.white.withValues(alpha: 0.85)
                          : AppColors.black.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}