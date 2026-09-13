import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/neo_brutalism_theme.dart';
import '../../../domain/entities/default_time_slot_entity.dart';
import 'cafe_section_title.dart';

/// Grid hiển thị ghế trống theo khung giờ (Morning/Afternoon/Evening/
/// LateNight) — render từ raw keys trong `availableSeatsByTimeSlot` của API.
///
/// BR-NEW-15 (2026-08-18): keys là string thô từ server. UI bind qua
/// `TimeSlotKey.fromApiName(...)` để lấy icon/label. Custom key (manager
/// override) sẽ được bỏ qua vì không map được sang enum.
class TimeSlotGrid extends StatelessWidget {
  /// Raw map từ server `availableSeatsByTimeSlot`.
  final Map<String, int> availableSeatsByTimeSlot;

  /// Total seats của quán — dùng để tính % hiển thị ghế trống.
  final int? totalSeats;

  const TimeSlotGrid({
    super.key,
    required this.availableSeatsByTimeSlot,
    this.totalSeats,
  });

  @override
  Widget build(BuildContext context) {
    final slots = availableSeatsByTimeSlot;
    if (slots.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final total = totalSeats ?? 0;

    // Sắp xếp theo thứ tự BR-NEW-15 (morning → lateNight) cho UI ổn định.
    final orderedKeys = slots.keys.toList()
      ..sort((a, b) {
        final ka = TimeSlotKey.fromApiName(a)?.index ?? 99;
        final kb = TimeSlotKey.fromApiName(b)?.index ?? 99;
        return ka.compareTo(kb);
      });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.lg),
        const CafeSectionTitle(
          title: 'Ghế trống theo khung giờ',
          icon: Icons.schedule_rounded,
        ),
        const SizedBox(height: AppSpacing.sm),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: AppSpacing.xs,
          mainAxisSpacing: AppSpacing.xs,
          childAspectRatio: 2.2,
          children: [
            for (final apiKey in orderedKeys)
              if (TimeSlotKey.fromApiName(apiKey) != null)
                _TimeSlotTile(
                  slotKey: TimeSlotKey.fromApiName(apiKey)!,
                  available: slots[apiKey]!,
                  total: total,
                  isDark: isDark,
                ),
          ],
        ),
      ],
    );
  }
}

class _TimeSlotTile extends StatelessWidget {
  final TimeSlotKey slotKey;
  final int available;
  final int total;
  final bool isDark;

  const _TimeSlotTile({
    required this.slotKey,
    required this.available,
    required this.total,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pct = total > 0 ? (available / total * 100).clamp(0, 100) : 0;
    final color = pct >= 70
        ? AppColors.success
        : pct >= 30
            ? AppColors.warning
            : AppColors.error;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.border,
          width: NeoBrutalismTheme.borderWidth,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(slotKey.icon, size: 18, color: color),
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  slotKey.displayLabel,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondary,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  // Chỉ hiển thị số ghế trống trong khung giờ, không "X/Y"
                  // (capacity cố định = totalSeats đã hiển thị ở card trên).
                  '$available',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
