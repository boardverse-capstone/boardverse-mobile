import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/neo_brutalism_theme.dart';
import '../../../domain/entities/cafe_detail_entity.dart';

/// Card hiển thị chi tiết ghế của quán: sức chứa (totalSeats) + breakdown
/// trống / giữ / đang dùng.
///
/// `availableSeats` từ API là tổng ghế trống cộng dồn qua 4 time-slot
/// (Morning/Afternoon/Evening/LateNight), không phải ghế trống hiện tại.
/// Ghế trống hiện tại được tính = `totalSeats - heldSeats - inUseSeats`.
/// Dùng cho trang chi tiết — UI lớn, dễ đọc hơn so với
/// [SeatAvailabilityIndicator] ở cafe card trên list.
class SeatCapacityCard extends StatelessWidget {
  final CafeDetailEntity cafe;

  const SeatCapacityCard({super.key, required this.cafe});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final total = cafe.totalSeats ?? 0;
    final held = cafe.heldSeats;
    final inUse = cafe.inUseSeats;
    // Ghế trống khả dụng hiện tại = totalSeats - heldSeats - inUseSeats.
    // Clamp về 0 phòng trường hợp backend trả held+inUse > totalSeats.
    final available = (total - held - inUse).clamp(0, total);
    final occupied = held + inUse;
    final pct = total > 0 ? (occupied / total * 100).clamp(0.0, 100.0) : 0.0;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.border,
          width: NeoBrutalismTheme.borderWidth,
        ),
        boxShadow: NeoBrutalismTheme.lightShadow(
          shadowColor: AppColors.black.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.event_seat_rounded,
                  size: 22,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SỨC CHỨA',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondary,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    // Chỉ hiển thị sức chứa (totalSeats), không phải
                    // availableSeats (vì field đó là tổng across time-slots,
                    // không phải ghế trống hiện tại).
                    Text(
                      total > 0 ? '$total ghế' : '—',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (total > 0) ...[
            const SizedBox(height: AppSpacing.md),
            // Stacked progress bar (held + inUse)
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                height: 14,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final heldW = (held / total) * constraints.maxWidth;
                    final inUseW = (inUse / total) * constraints.maxWidth;
                    final availableW =
                        constraints.maxWidth - heldW - inUseW;
                    return Row(
                      children: [
                        if (availableW > 0)
                          Expanded(
                            flex: (available * 1000).round().clamp(1, 1 << 30),
                            child: Container(color: AppColors.success),
                          ),
                        if (heldW > 0)
                          SizedBox(
                            width: heldW,
                            child: Container(color: AppColors.warning),
                          ),
                        if (inUseW > 0)
                          SizedBox(
                            width: inUseW,
                            child: Container(color: AppColors.error),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '${pct.toStringAsFixed(0)}% đang sử dụng',
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          // Legend / breakdown — hiển thị số lượng đơn lẻ, không "X/Y".
          Row(
            children: [
              Expanded(
                child: _StatPill(
                  icon: Icons.check_circle_rounded,
                  color: AppColors.success,
                  label: 'Trống',
                  value: available.toString(),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: _StatPill(
                  icon: Icons.hourglass_bottom_rounded,
                  color: AppColors.warning,
                  label: 'Giữ chỗ',
                  value: held.toString(),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: _StatPill(
                  icon: Icons.bolt_rounded,
                  color: AppColors.error,
                  label: 'Đang dùng',
                  value: inUse.toString(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;

  const _StatPill({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondary,
                    letterSpacing: 0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}