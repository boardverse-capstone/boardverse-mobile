import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/cafe_entity.dart';
import '../../domain/entities/seat_availability_entity.dart';

/// Widget hiển thị trạng thái ghế của quán
/// Tuân thủ BR-01: Seat-based management
class SeatAvailabilityIndicator extends StatelessWidget {
  final CafeEntity? cafe;
  final SeatAvailabilityEntity? availability;
  final bool isLoading;
  final bool showDetailedInfo;
  final VoidCallback? onTap;

  const SeatAvailabilityIndicator({
    super.key,
    this.cafe,
    this.availability,
    this.isLoading = false,
    this.showDetailedInfo = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (isLoading) {
      return _buildLoadingIndicator(theme);
    }

    if (availability != null) {
      return _buildDetailedIndicator(context, theme);
    }

    if (cafe != null) {
      return _buildCafeIndicator(context, theme);
    }

    return const SizedBox.shrink();
  }

  Widget _buildLoadingIndicator(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: AppRadius.radiusLgAll,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: AppSpacing.sm + 2,
            height: AppSpacing.sm + 2,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text('Đang kiểm tra...', style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }

  Widget _buildCafeIndicator(BuildContext context, ThemeData theme) {
    final status = cafe!.seatStatus;
    final (color, icon, label) = _getStatusInfo(status, cafe!.availableSeats);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: AppRadius.radiusLgAll,
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: AppSpacing.md, color: color),
            const SizedBox(width: AppSpacing.xs),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedIndicator(BuildContext context, ThemeData theme) {
    final status = availability!.overallStatus;
    final (color, icon, label) = _getOverallStatusInfo(status);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: AppSpacing.paddingAllSm,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: AppRadius.radiusSmAll,
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(icon, size: AppSpacing.md + 2, color: color),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  label,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Text(
                  '${availability!.availableSeats}/${availability!.totalSeats} ghế',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            if (showDetailedInfo) ...[
              const SizedBox(height: AppSpacing.xs),
              _buildSeatBreakdown(theme),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSeatBreakdown(ThemeData theme) {
    return Column(
      children: [
        _buildSeatRow(
          theme,
          'Đang giữ chờ',
          availability!.holdingSeats,
          AppColors.warning,
        ),
        _buildSeatRow(
          theme,
          'Đã đặt cọc',
          availability!.reservedSeats,
          AppColors.info,
        ),
        _buildSeatRow(
          theme,
          'Đang sử dụng',
          availability!.inUseSeats,
          AppColors.error,
        ),
      ],
    );
  }

  Widget _buildSeatRow(ThemeData theme, String label, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
      child: Row(
        children: [
          Container(
            width: AppSpacing.xs,
            height: AppSpacing.xs,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(label, style: theme.textTheme.bodySmall),
          const Spacer(),
          Text(
            '$count',
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  (Color, IconData, String) _getStatusInfo(
    CafeSeatStatus status,
    int available,
  ) {
    switch (status) {
      case CafeSeatStatus.available:
        return (AppColors.success, Icons.event_seat, '$available ghế trống');
      case CafeSeatStatus.limited:
        return (AppColors.warning, Icons.warning_amber, 'Còn $available ghế');
      case CafeSeatStatus.full:
        return (AppColors.error, Icons.block, 'Hết ghế');
    }
  }

  (Color, IconData, String) _getOverallStatusInfo(SeatOverallStatus status) {
    switch (status) {
      case SeatOverallStatus.plenty:
        return (AppColors.success, Icons.event_seat, 'Nhiều ghế trống');
      case SeatOverallStatus.moderate:
        return (AppColors.info, Icons.event_seat, 'Vừa đủ chỗ');
      case SeatOverallStatus.limited:
        return (AppColors.warning, Icons.warning_amber, 'Ít ghế trống');
      case SeatOverallStatus.unavailable:
        return (AppColors.error, Icons.block, 'Hết ghế');
    }
  }
}