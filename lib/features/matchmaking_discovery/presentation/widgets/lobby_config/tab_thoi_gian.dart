import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import 'bottom_button.dart';
import 'buffer_info_card.dart';

/// Tab 2 của LobbyConfigPage — chọn ngày + giờ bắt đầu / kết thúc dự kiến.
///
/// BR-NEW (2026-08-27): Backend không còn xử lý `timeSlot` enum, player tự
/// do chọn ngày + giờ bắt đầu / kết thúc trong cùng 1 ngày. Không còn
/// chip chọn phiên (Sáng/Chiều/Tối/Khuya).
///
/// BR-NEW-15 (2026-09): Hỗ trợ overnight — nếu `preferredEndTime <
/// preferredStartTime` thì `scheduledEndTime = playDate + 1`. Tab hiển thị
/// badge "+1 ngày" trên End Time khi [endCrossesMidnight] = true.
class LobbyConfigTabThoiGian extends StatelessWidget {
  final DateTime selectedDate;
  final TimeOfDay? preferredStartTime;
  final TimeOfDay? preferredEndTime;

  /// `true` khi `preferredEndTime` rơi vào ngày kế tiếp so với
  /// `preferredStartTime` (tức end < start tính theo phút). Khi true,
  /// tab hiển thị badge "+1 ngày" trên End Time để user biết lobby
  /// kéo dài qua đêm.
  final bool endCrossesMidnight;

  final ValueChanged<DateTime> onDateSelected;
  final VoidCallback onOpenDatePicker;
  final VoidCallback onPreferredTimeTap;
  final VoidCallback onPreferredEndTimeTap;
  final String Function(DateTime) formatDate;
  final String Function(TimeOfDay) formatTime;
  final int bufferMinutes;
  final bool isScheduledInPast;
  final bool hasBufferWarning;

  /// `true` khi buffer nằm trong vùng "không đủ thời gian tuyển người"
  /// (30–60 phút, BR §XXI-B.6). UI sẽ hiển thị warning màu warningDark
  /// trên buffer info card.
  final bool isBufferInsufficient;

  /// `false` khi nút "Tiếp tục" phải disable (BR §XXI-B.6):
  /// - scheduledTime ở quá khứ, HOẶC
  /// - buffer < 30 phút (không đủ thời gian chuẩn bị cho group), HOẶC
  /// - preferredEndTime == preferredStartTime (BR-PreferredTimesMustDiffer).
  final bool canProceed;

  /// Lý do disable (hiển thị trong banner đỏ ngay trên nút "Tiếp tục").
  /// `null` khi [canProceed] = true.
  final String? cannotProceedReason;

  final String Function(int) formatBuffer;

  /// Quay lại tab trước (Thời gian → Quán & Game). Được wire từ
  /// nút "Quay lại" ở bottom action bar — thay thế cho nút back trên
  /// AppBar để tránh chạm nhầm dẫn đến pop cả page.
  final VoidCallback onPrev;

  final VoidCallback onNext;

  const LobbyConfigTabThoiGian({
    super.key,
    required this.selectedDate,
    required this.preferredStartTime,
    required this.preferredEndTime,
    required this.endCrossesMidnight,
    required this.onDateSelected,
    required this.onOpenDatePicker,
    required this.onPreferredTimeTap,
    required this.onPreferredEndTimeTap,
    required this.formatDate,
    required this.formatTime,
    required this.formatBuffer,
    required this.bufferMinutes,
    required this.isScheduledInPast,
    required this.hasBufferWarning,
    required this.isBufferInsufficient,
    required this.canProceed,
    required this.cannotProceedReason,
    required this.onPrev,
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

                // Info banner khi lobby kéo dài qua đêm (BR-NEW-15).
                // Hiển thị cảnh báo trực quan giúp user không bị bất ngờ
                // khi nhìn thấy end < start trên End Time.
                if (endCrossesMidnight) ...[
                  _OvernightBanner(
                    endDate: selectedDate.add(const Duration(days: 1)),
                    formatDate: formatDate,
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],

                // Preferred start time
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
                                    : 'Chọn giờ',
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
                        // Badge "+1 ngày" khi overnight (BR-NEW-15).
                        if (endCrossesMidnight) ...[
                          const _NextDayBadge(),
                          const SizedBox(width: AppSpacing.xs),
                        ],
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
                  isInsufficient: isBufferInsufficient,
                  formatBuffer: formatBuffer,
                ),
              ],
            ),
          ),
        ),

        // Banner lý do disable nút "Tiếp tục" — chỉ hiển thị khi
        // [canProceed] = false. Đặt NGOÀI (icon báo + text) để
        // player thấy ngay khi scroll xuống.
        if (!canProceed && cannotProceedReason != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              0,
            ),
            child: _CannotProceedBanner(message: cannotProceedReason!),
          ),

        LobbyConfigBottomButton(
          // Disable khi [canProceed] = false (quá khứ, buffer < 30p,
          // hoặc endTime == startTime). Xem [_canProceed] trong
          // `lobby_config_page.dart` (BR §XXI-B.6, cập nhật 2026-10-01).
          label: 'Tiếp tục',
          onPressed: canProceed ? onNext : null,
          secondaryLabel: 'Quay lại',
          secondaryOnPressed: onPrev,
        ),
      ],
    );
  }

  String _getWeekdayShort(int weekday) {
    const days = ['CN', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7'];
    return days[weekday % 7];
  }
}

/// Banner inline hiển thị lý do KHÔNG cho phép tiếp tục (buffer quá
/// ngắn hoặc quá khứ). Style: error (đỏ) nền nhạt + icon + text.
/// Đặt ngay trên nút "Tiếp tục" để player thấy ngay khi scroll xuống.
class _CannotProceedBanner extends StatelessWidget {
  final String message;
  const _CannotProceedBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.error,
          width: 1.5,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_rounded,
            color: AppColors.error,
            size: 18,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w800,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// OVERNIGHT UI HELPERS — BR-NEW-15 (cross-midnight reservation)
// ═══════════════════════════════════════════════════════════════════════

/// Banner cảnh báo lobby kéo dài qua đêm. Hiển thị ngay phía trên
/// Start/End Time picker khi `endTime < startTime` — giúp user nhận
/// biết rằng end time thuộc NGÀY KẾ TIẾP của `playDate`.
///
/// VD: playDate = T3 8/9, start = 23:00, end = 05:00 → banner hiển thị
/// "Lobby sẽ kết thúc lúc 05:00 ngày mai (T4, 09/09)".
class _OvernightBanner extends StatelessWidget {
  final DateTime endDate;
  final String Function(DateTime) formatDate;

  const _OvernightBanner({required this.endDate, required this.formatDate});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final secondary = theme.colorScheme.secondary;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: secondary.withValues(alpha: 0.1),
        borderRadius: AppRadius.radiusMdAll,
        border: Border.all(color: secondary, width: 1.5),
      ),
      child: Row(
        children: [
          Icon(Icons.nightlight_round, color: secondary, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Lobby kéo dài qua đêm',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: secondary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Sẽ kết thúc vào ${formatDate(endDate)} lúc theo giờ đã chọn',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Badge "+1 ngày" hiển thị kế bên End Time value khi reservation
/// cross midnight. Pill nhỏ, không border đậm để không cạnh tranh
/// attention với nội dung chính.
class _NextDayBadge extends StatelessWidget {
  const _NextDayBadge();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final secondary = theme.colorScheme.secondary;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: secondary.withValues(alpha: 0.15),
        borderRadius: AppRadius.radiusFullAll,
        border: Border.all(color: secondary.withValues(alpha: 0.5), width: 1),
      ),
      child: Text(
        '+1 ngày',
        style: theme.textTheme.labelSmall?.copyWith(
          color: secondary,
          fontWeight: FontWeight.w800,
          fontSize: 10,
        ),
      ),
    );
  }
}
