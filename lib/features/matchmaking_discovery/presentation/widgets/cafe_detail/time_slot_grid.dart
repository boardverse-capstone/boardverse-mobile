import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/neo_brutalism_theme.dart';
import '../../../domain/entities/cafe_detail_entity.dart';
import 'cafe_section_title.dart';
import 'time_slot_icon_x.dart';

/// Grid hiển thị ghế trống theo khung giờ (Morning/Afternoon/Evening/
/// LateNight) — map từ `availableSeatsByTimeSlot` của API.
///
/// Chỉ render khi cafe có data; nếu không có thì trả về SizedBox.shrink().
class TimeSlotGrid extends StatelessWidget {
  final CafeDetailEntity cafe;

  const TimeSlotGrid({super.key, required this.cafe});

  @override
  Widget build(BuildContext context) {
    final slots = cafe.availableSeatsByTimeSlot;
    if (slots.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final total = cafe.totalSeats ?? 0;

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
            for (final slot in TimeSlot.values)
              if (slots.containsKey(slot))
                _TimeSlotTile(
                  slot: slot,
                  available: slots[slot]!,
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
  final TimeSlot slot;
  final int available;
  final int total;
  final bool isDark;

  const _TimeSlotTile({
    required this.slot,
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
            child: Icon(slot.icon, size: 18, color: color),
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  slot.displayLabel,
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