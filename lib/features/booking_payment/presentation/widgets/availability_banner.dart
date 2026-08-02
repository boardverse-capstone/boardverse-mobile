import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';
import '../../domain/entities/cafe_availability_entity.dart';

/// Banner cảnh báo "quán hết chỗ" + gợi ý slot thay thế (gap #2).
///
/// Render đầu `BookingSummaryPage` khi `hasCapacity == false`. Nếu backend
/// có trả về `alternativeSlots`, hiển thị chip cho user chọn nhanh.
class AvailabilityBanner extends StatelessWidget {
  final CafeAvailabilityEntity availability;

  /// Callback khi user pick 1 alternative slot. Cập nhật `_scheduledEndTime`
  /// + reload `availableTables` ở BookingSummaryCubit.
  final ValueChanged<AlternativeSlotEntity> onPickAlternative;

  const AvailabilityBanner({
    super.key,
    required this.availability,
    required this.onPickAlternative,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasCapacity = availability.hasCapacity;
    final isFull = !hasCapacity;
    final color = isFull ? theme.colorScheme.error : theme.colorScheme.tertiary;
    final iconData =
        isFull ? Icons.event_busy_rounded : Icons.check_circle_rounded;
    final headline = isFull
        ? 'Quán hết chỗ trong khung giờ này'
        : 'Còn ${availability.availableSeats}/${availability.totalSeats} ghế';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: AppRadius.cardRadius,
        border: Border.all(color: color.withValues(alpha: 0.40)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(iconData, size: AppIcons.md, color: color),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  headline,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          if (availability.availableGameBoxCount != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Hộp game còn: ${availability.availableGameBoxCount}',
              style: theme.textTheme.bodySmall,
            ),
          ],
          if (availability.selectedGameAvailabilityStatus != null) ...[
            const SizedBox(height: 2),
            Text(
              'Trạng thái game: '
              '${availability.selectedGameAvailabilityStatus}',
              style: theme.textTheme.bodySmall,
            ),
          ],
          if (isFull && availability.alternativeSlots.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Khung giờ thay thế:',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: availability.alternativeSlots
                  .take(5)
                  .map(
                    (slot) => ActionChip(
                      avatar: const Icon(
                        Icons.access_time_rounded,
                        size: 16,
                      ),
                      label: Text(
                        '${_hhmm(slot.startTime)} → ${_hhmm(slot.endTime)} '
                        '(${slot.availableSeats} ghế)',
                      ),
                      onPressed: () => onPickAlternative(slot),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  String _hhmm(DateTime dt) {
    final local = dt.toLocal();
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }
}