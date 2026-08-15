import 'package:flutter/material.dart';

import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../reservation/domain/entities/entities.dart';
import 'bottom_button.dart';
import 'buffer_info_card.dart';

/// Tab 2 của LobbyConfigPage — chọn ngày + phiên chơi + giờ dự kiến.
class LobbyConfigTabThoiGian extends StatelessWidget {
  final DateTime selectedDate;
  final TimeSlot selectedTimeSlot;
  final TimeOfDay? preferredStartTime;
  final TimeOfDay? preferredEndTime;
  final List<TimeSlot> availableSlots;
  final ValueChanged<DateTime> onDateSelected;
  final VoidCallback onOpenDatePicker;
  final ValueChanged<TimeSlot> onTimeSlotChanged;
  final VoidCallback onPreferredTimeTap;
  final VoidCallback onPreferredEndTimeTap;
  final String Function(DateTime) formatDate;
  final String Function(TimeOfDay) formatTime;
  final TimeOfDay Function(TimeSlot) getSlotStartTime;
  final TimeOfDay Function(TimeSlot) getSlotEndTime;
  final String Function(TimeSlot) getSlotLabel;
  final String Function(TimeSlot) getSlotShortLabel;
  final IconData Function(TimeSlot) getSlotIcon;
  final Color Function(TimeSlot, ColorScheme) getSlotColor;
  final int bufferMinutes;
  final bool isScheduledInPast;
  final bool hasBufferWarning;
  final String Function(int) formatBuffer;
  final VoidCallback onNext;

  const LobbyConfigTabThoiGian({
    super.key,
    required this.selectedDate,
    required this.selectedTimeSlot,
    required this.preferredStartTime,
    required this.preferredEndTime,
    required this.availableSlots,
    required this.onDateSelected,
    required this.onOpenDatePicker,
    required this.onTimeSlotChanged,
    required this.onPreferredTimeTap,
    required this.onPreferredEndTimeTap,
    required this.formatDate,
    required this.formatTime,
    required this.getSlotStartTime,
    required this.getSlotEndTime,
    required this.getSlotLabel,
    required this.getSlotShortLabel,
    required this.getSlotIcon,
    required this.getSlotColor,
    required this.bufferMinutes,
    required this.isScheduledInPast,
    required this.hasBufferWarning,
    required this.formatBuffer,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dates = List.generate(7, (i) => today.add(Duration(days: i)));
    final isSelectedInChips = dates.any((d) =>
        d.year == selectedDate.year &&
        d.month == selectedDate.month &&
        d.day == selectedDate.day);

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: AppSpacing.paddingAllMd,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Ngày hẹn',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (!isSelectedInChips)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: AppRadius.radiusFullAll,
                        ),
                        child: Text(
                          formatDate(selectedDate),
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),

                // Date chips
                SizedBox(
                  height: 72,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: dates.length,
                    separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      final date = dates[index];
                      final isSelected = date.year == selectedDate.year &&
                          date.month == selectedDate.month &&
                          date.day == selectedDate.day;

                      return GestureDetector(
                        onTap: () => onDateSelected(date),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 64,
                          height: 72,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.surfaceContainerHigh,
                            borderRadius: AppRadius.radiusMdAll,
                            border: isSelected
                                ? null
                                : Border.all(color: theme.colorScheme.outlineVariant),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '${date.day}',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isSelected
                                      ? theme.colorScheme.onPrimary
                                      : theme.colorScheme.onSurface,
                                ),
                              ),
                              Text(
                                _getWeekdayShort(date.weekday),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: isSelected
                                      ? theme.colorScheme.onPrimary.withValues(alpha: 0.8)
                                      : theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: AppSpacing.sm),

                // Calendar button for dates beyond 7 days
                TextButton.icon(
                  onPressed: onOpenDatePicker,
                  icon: const Icon(Icons.calendar_month, size: 18),
                  label: const Text('Chọn ngày khác...'),
                ),

                const SizedBox(height: AppSpacing.lg),
                const Divider(),
                const SizedBox(height: AppSpacing.lg),

                // Time slot section
                Text(
                  'Phiên chơi',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),

                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: availableSlots.map((slot) {
                    final isSelected = slot == selectedTimeSlot;
                    final color = getSlotColor(slot, theme.colorScheme);

                    return GestureDetector(
                      onTap: () => onTimeSlotChanged(slot),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                          vertical: AppSpacing.md,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? color.withValues(alpha: 0.15)
                              : theme.colorScheme.surfaceContainerHigh,
                          borderRadius: AppRadius.radiusMdAll,
                          border: Border.all(
                            color: isSelected ? color : theme.colorScheme.outlineVariant,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              getSlotIcon(slot),
                              color: isSelected ? color : theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  getSlotShortLabel(slot),
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? color : theme.colorScheme.onSurface,
                                  ),
                                ),
                                Text(
                                  _getSlotTimeRange(slot),
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: AppSpacing.md),

                // Preferred time
                GestureDetector(
                  onTap: onPreferredTimeTap,
                  child: Container(
                    padding: AppSpacing.paddingAllMd,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHigh,
                      borderRadius: AppRadius.radiusMdAll,
                      border: Border.all(color: theme.colorScheme.outlineVariant),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.play_arrow, color: theme.colorScheme.primary),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Giờ bắt đầu',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              Text(
                                preferredStartTime != null
                                    ? formatTime(preferredStartTime!)
                                    : 'Chọn giờ (tuỳ chọn)',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right, color: theme.colorScheme.onSurfaceVariant),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.sm),

                // Preferred end time
                GestureDetector(
                  onTap: onPreferredEndTimeTap,
                  child: Container(
                    padding: AppSpacing.paddingAllMd,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHigh,
                      borderRadius: AppRadius.radiusMdAll,
                      border: Border.all(color: theme.colorScheme.outlineVariant),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.stop, color: theme.colorScheme.secondary),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Giờ kết thúc (tuỳ chọn)',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              Text(
                                preferredEndTime != null
                                    ? formatTime(preferredEndTime!)
                                    : 'Mặc định theo phiên',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right, color: theme.colorScheme.onSurfaceVariant),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),

                // Buffer info
                LobbyConfigBufferInfoCard(
                  bufferMinutes: bufferMinutes,
                  hasBufferWarning: hasBufferWarning,
                  formatBuffer: formatBuffer,
                ),
              ],
            ),
          ),
        ),

        LobbyConfigBottomButton(
          // CHỈ disable khi `scheduledTime` đã ở quá khứ. Buffer ngắn
          // (< 60 phút) chỉ hiển thị warning — vẫn cho user đặt lobby
          // sát giờ theo BR §XXI-B.4.
          label: 'Tiếp tục',
          onPressed: isScheduledInPast ? null : onNext,
        ),
      ],
    );
  }

  String _getWeekdayShort(int weekday) {
    const days = ['CN', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7'];
    return days[weekday % 7];
  }

  String _getSlotTimeRange(TimeSlot slot) {
    final start = formatTime(getSlotStartTime(slot));
    final end = formatTime(getSlotEndTime(slot));
    return '$start - $end';
  }
}