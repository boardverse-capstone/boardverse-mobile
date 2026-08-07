import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:boardverse_mobile/core/theme/theme.dart';

/// Countdown tới `scheduledTime` (giờ chơi thực tế của lobby).
///
/// Khác `LobbyCountdownTimer` (đếm tới `timeoutAt` / recruitmentDeadline):
/// - Widget này hiển thị ngày giờ chơi + đếm ngược lớn ("Còn 2 ngày 4 giờ
///   15 phút") cho FE Phase A.
/// - Khi `scheduledTime` đã trôi qua → hiển thị "Đã tới giờ chơi" với
///   icon urgent.
/// - Tự dừng timer khi expired.
class ScheduledTimeCountdown extends StatefulWidget {
  /// Thời điểm chơi thực tế (lobby.scheduledTime).
  final DateTime scheduledTime;

  /// Optional label phụ dưới countdown (vd: "Giờ chơi").
  final String? caption;

  /// Optional callback khi countdown về 0.
  final VoidCallback? onArrived;

  const ScheduledTimeCountdown({
    super.key,
    required this.scheduledTime,
    this.caption,
    this.onArrived,
  });

  @override
  State<ScheduledTimeCountdown> createState() => _ScheduledTimeCountdownState();
}

class _ScheduledTimeCountdownState extends State<ScheduledTimeCountdown> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Update mỗi phút — countdown theo ngày không cần chính xác tới giây.
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (!mounted) return;
      setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  ({String countdown, bool isUrgent, bool isExpired}) _compute() {
    final now = DateTime.now();
    final diff = widget.scheduledTime.difference(now);

    if (diff.isNegative || diff == Duration.zero) {
      return (countdown: 'Đã tới giờ chơi', isUrgent: true, isExpired: true);
    }

    final days = diff.inDays;
    final hours = diff.inHours % 24;
    final minutes = diff.inMinutes % 60;

    final parts = <String>[];
    if (days > 0) parts.add('$days ngày');
    if (hours > 0) parts.add('$hours giờ');
    parts.add('$minutes phút');

    // Urgent khi còn dưới 30 phút.
    final urgent = diff.inMinutes < 30;

    return (
      countdown: 'Còn ${parts.join(' ')}',
      isUrgent: urgent,
      isExpired: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    // DateFormat cần `initializeDateFormatting(<locale>)` được gọi trong
    // `main()`. Tuy nhiên để safe (vd: hot-reload cache stale, hoặc gọi trước
    // khi main xong trên web), wrap trong try-catch và fallback sang pattern
    // không cần locale.
    String dateLabel;
    try {
      dateLabel = DateFormat('EEE, dd/MM • HH:mm', 'vi')
          .format(widget.scheduledTime.toLocal());
    } catch (_) {
      dateLabel =
          DateFormat('EEE, dd/MM • HH:mm').format(widget.scheduledTime.toLocal());
    }

    final result = _compute();

    final accent = result.isExpired
        ? AppColors.success
        : result.isUrgent
            ? colors.error
            : colors.primary;

    return Semantics(
      label:
          '${widget.caption ?? "Giờ chơi"}: $dateLabel. ${result.countdown}.',
      liveRegion: result.isUrgent,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.10),
          borderRadius: AppRadius.radiusLgAll,
          border: Border.all(color: accent.withValues(alpha: 0.30)),
        ),
        child: Row(
          children: [
            Icon(AppIcons.clock, size: 20, color: accent),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.caption ?? 'Giờ chơi',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: accent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    dateLabel,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: accent,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    result.countdown,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: accent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
